require "opencv"
include OpenCV

CONFIG = Config.new

class VideoChannel < ApplicationCable::Channel
  def subscribed
    stream_for uuid
  end

  def start
    puts 'start'
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

    DebugRenderChannel.broadcast_to uuid, description: 'f0', imageUri: output_uri, createdAt: data['created_at']

    CONFIG.colors.each do |color|
      output = color.map image

      tmp_file =  'tmp/output.png'
      output.save_image tmp_file
      output_encoded = Base64.strict_encode64 File.open(tmp_file, 'rb').read
      output_uri = "data:image/png;base64,#{output_encoded}"
      DebugRenderChannel.broadcast_to uuid, description: "fHSV #{color.name}", imageUri: output_uri, createdAt: data['created_at']
    end

    VideoChannel.broadcast_to uuid, action: 'snap'
  end
end
