require 'opencv'
include OpenCV

class VideoChannel < ApplicationCable::Channel

  def subscribed
    stream_for uuid
    config = Configs.instance.get uuid
    VideoChannel.broadcast_to uuid, action: 'ready', config_updated_at: config.updated_at
  end

  def frame(data)
    image = IplImage.load_from_data_uri data['image_uri']
    created_at = data['created_at']
    config = Configs.instance.get uuid

    DebugRenderChannel.broadcast_to uuid, id: :latest_frame, at: created_at, uri: image.to_data_uri

    outline_image = image.clone
    config.track.render_outline_to outline_image, CvColor::Green
    DebugRenderChannel.broadcast_to uuid, id: :outline, at: created_at, uri: outline_image.to_data_uri

    masked_image = config.track_mask.mask_image image
    DebugRenderChannel.broadcast_to uuid, id: :masked, at: created_at, uri: masked_image.to_data_uri

    case config.video_mode
    when :capturing_null_image
      null_image_frame config, masked_image, created_at
    else
      race_frame config, masked_image, created_at
    end

    VideoChannel.broadcast_to uuid, action: 'snap'
  end

  private

  def null_image_frame(config, image, created_at)
    null_image = config.null_image.add_frame image
    meta = { frame_count: config.null_image.frame_count }
    DebugRenderChannel.broadcast_to uuid, id: :null_image, at: created_at, uri: null_image.to_data_uri, meta: meta.to_json
  end

  def race_frame(config, image, created_at)
    return unless config.null_image

    diff_image = DiffImage.new config.null_image.image, image, config.null_image_threshold
    diff_image.diff.split.each_with_index do |diff, i|
      DebugRenderChannel.broadcast_to uuid, id: "diff_image_#{i}", at: created_at, uri: diff.to_data_uri
    end

    car_finder = config.car_finder
    diff_mask = diff_image.mask
    diff_mask_meta = { max_car_pixels: car_finder.expected_total_pixel_count, pixels: diff_mask.count_non_zero }
    DebugRenderChannel.broadcast_to uuid, id: :diff_mask, at: created_at, uri: diff_mask.to_data_uri, meta: diff_mask_meta.to_json

    result_image = image.clone
    panic = diff_mask.count_non_zero > car_finder.expected_total_pixel_count
    result_image.put_text! 'PANIC', CvPoint.new(image.rows / 2, image.columns / 2), CvFont.new(:simplex, hscale: 5, thickness: 3), CvColor::Red if panic

    cleaned_image = diff_image.cleaned
    DebugRenderChannel.broadcast_to uuid, id: :cleaned_image, at: created_at, uri: cleaned_image.to_data_uri, meta: { panic: panic }.to_json

    car_finder.handle_image cleaned_image unless panic


    config.colors.each do |color|
      color_mask = color.hsv_map cleaned_image
      DebugRenderChannel.broadcast_to uuid, id: "#{ color.name }_mask", at: created_at, uri: color_mask.to_data_uri
      cleaned_color_image = image.clone.set CvColor::White, color_mask.not

      position = car_finder.colors_positions[color].to_point
      car_tracker = config.car_trackers[color]
      if position
        cleaned_color_image.crosshair! position
        car_tracker.on_track! position
      else
        car_tracker.off_track!
      end

      car_tracker.render_last_position_to result_image

      DebugRenderChannel.broadcast_to uuid, id: color.name, at: created_at, uri: cleaned_color_image.to_data_uri

    end
    DebugRenderChannel.broadcast_to uuid, id: :result, at: created_at, uri: result_image.to_data_uri
  end
end
