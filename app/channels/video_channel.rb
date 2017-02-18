require "opencv"
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

    output = image.clone
    output.put_text!(Time.current.strftime('%H:%M:%S'), CvPoint2D32f.new(40, 20), CvFont.new(:duplex), CvColor::White)

    tmp_file =  'tmp/output.png'
    output.save_image tmp_file
    output_encoded = Base64.strict_encode64 File.open(tmp_file, 'rb').read
    output_uri = "data:image/png;base64,#{output_encoded}"

    config = Configs.instance.get uuid
    config.colors.each do |color|
      output = color.hsv_map image

      tmp_file =  'tmp/output.png'
      output.save_image tmp_file
      output_encoded = Base64.strict_encode64 File.open(tmp_file, 'rb').read
      output_uri = "data:image/png;base64,#{output_encoded}"

      image_attrs = { uri: output_uri, createdAt: data['created_at'] }
      DebugRenderChannel.broadcast_to uuid, config: color.to_json, image: image_attrs.to_json
    end

    VideoChannel.broadcast_to uuid, action: 'snap'
  end
end
