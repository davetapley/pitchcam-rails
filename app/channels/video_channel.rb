require "opencv"
include OpenCV

class VideoChannel < ApplicationCable::Channel
  def subscribed
    stream_for uuid
  end

  def start
    puts 'start'
  end

  def frame(data)
    uri = URI::Data.new data['image_uri']
    puts uri.content_type

    File.open('tmp/image.jpg', 'wb') { |f| f.write(uri.data) }
    image = IplImage.load 'tmp/image.jpg'

    output = image.clone
    output.put_text!(Time.current.strftime('%H:%M:%S'), CvPoint2D32f.new(40, 20), CvFont.new(:duplex), CvColor::White)

    tmp_file =  'tmp/output.png'
    output.save_image tmp_file
    output_encoded = Base64.strict_encode64 File.open(tmp_file, 'rb').read
    output_uri = "data:image/png;base64,#{output_encoded}"

    VideoChannel.broadcast_to uuid, action: 'snap'
    DebugRenderChannel.broadcast_to uuid, description: 'default', imageUri: output_uri, createdAt: Time.current
  end
end
