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
    DebugRenderChannel.broadcast_to uuid, id: :track, at: created_at, uri: outline_image.to_data_uri


    case config.video_mode
    when :capturing_null_image
      null_image_frame config, image, created_at
    else
      race_frame config, image, created_at
    end

    VideoChannel.broadcast_to uuid, action: 'snap'
  end

  def render_color_crosshair_to(image, position)
    horiz_from = CvPoint.new 0, position.y
    horiz_to = CvPoint.new image.width, position.y
    image.line! horiz_from, horiz_to, thickness: 1, color: CvColor::Green

    vert_from = CvPoint.new position.x, 0
    vert_to = CvPoint.new position.x, image.height
    image.line! vert_from, vert_to, thickness: 1, color: CvColor::Green
  end

  private

  def null_image_frame(config, image, created_at)
    null_image = config.null_image.add_frame image
    debug = { frame_count: config.null_image.frame_count }
    DebugRenderChannel.broadcast_to uuid, id: :null_image, at: created_at, uri: null_image.to_data_uri, debug: debug.to_json
  end

  def race_frame(config, image, created_at)
    return unless config.null_image

    diff_image = DiffImage.new config.null_image.image, image, config.null_image_threshold
    diff_image.diff.split.each_with_index do |diff, i|
      DebugRenderChannel.broadcast_to uuid, id: "diff_image_#{i}", at: created_at, uri: diff.to_data_uri
    end
    DebugRenderChannel.broadcast_to uuid, id: :diff_mask, at: created_at, uri: diff_image.mask.to_data_uri
    DebugRenderChannel.broadcast_to uuid, id: :cleaned_image, at: created_at, uri: diff_image.cleaned.to_data_uri

    masked_image = config.track_mask.mask_image diff_image.cleaned
    DebugRenderChannel.broadcast_to uuid, id: :masked_image, at: created_at, uri: masked_image.to_data_uri

    car_finder = config.car_finder

    car_finder.handle_image masked_image

    config.colors.each do |color|
      color_mask = color.hsv_map masked_image
      masked_color_image = image.clone.set CvColor::White, color_mask.not

      positions = { world: car_finder.colors_positions[color].to_point }
      if positions[:world]
        positions[:track] = config.track.position_from_world positions[:world]
        render_color_crosshair_to masked_color_image, positions[:world]
      else
        positions[:track] = nil
      end

      DebugRenderChannel.broadcast_to uuid, id: color.name, at: created_at, uri: masked_color_image.to_data_uri
    end
  end
end
