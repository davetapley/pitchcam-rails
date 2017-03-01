require 'opencv'
include OpenCV

class VideoChannel < ApplicationCable::Channel
  def subscribed
    stream_for uuid
    config = Configs.instance.get uuid
    VideoChannel.broadcast_to uuid, action: 'ready', config_updated_at: config.updated_at
  end

  def frame(data)
    uri = URI::Data.new data['image_uri']
    File.open('tmp/image.jpg', 'wb') { |f| f.write(uri.data) }
    image = IplImage.load 'tmp/image.jpg'

    config = Configs.instance.get uuid
    config.track.render_outline_to image
    tmp_file =  'tmp/output.png'
    image.save_image tmp_file
    output_encoded = Base64.strict_encode64 File.open(tmp_file, 'rb').read
    output_uri = "data:image/png;base64,#{output_encoded}"

    image_attrs = { uri: output_uri, createdAt: data['created_at'] }
    DebugRenderChannel.broadcast_to uuid, color: false, image: image_attrs.to_json

    config.colors.each do |color|
      output = color.hsv_map image

      tmp_file =  'tmp/output.png'
      output.save_image tmp_file
      output_encoded = Base64.strict_encode64 File.open(tmp_file, 'rb').read
      output_uri = "data:image/png;base64,#{output_encoded}"

      image_attrs = { uri: output_uri, createdAt: data['created_at'] }
      DebugRenderChannel.broadcast_to uuid, color: true, name: color.name, image: image_attrs.to_json
    end


    #dirty_colors = image_processor.handle_image image

    VideoChannel.broadcast_to uuid, action: 'snap'
  end
end
