require "opencv"
include OpenCV

class VideoChannel < ApplicationCable::Channel
  def subscribed
    stream_for 'alice'
  end

  def start
    puts 'start'
  end

  def frame(data)
    uri = URI::Data.new data['image_uri']
    puts uri.content_type

    File.open('image.jpg', 'wb') { |f| f.write(uri.data) }
    image = IplImage.load 'image.jpg'

    output = image.clone
    output.put_text!('hello world', CvPoint2D32f.new(20, 20), CvFont.new(:simplex), CvColor::White)

    tmp_file =  'output.png'
    output.save_image tmp_file
    output_encoded = Base64.strict_encode64 File.open(tmp_file, 'rb').read
    output_uri = "data:image/png;base64,#{output_encoded}"

    VideoChannel.broadcast_to 'alice', imageUri: output_uri
  end
end
