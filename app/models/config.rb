require 'opencv'
include OpenCV

class Transform
  include ActiveModel::Serializers::JSON

  attr_accessor :origin_x, :origin_y, :scale, :rotation

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    instance_values
  end

  def origin
    CvPoint.new origin_x, origin_y
  end
end

class Config
  include ActiveModel::Serializers::JSON

  attr_accessor :layout
  attr_reader :updated_at, :world_transform, :colors, :color_window_on, :track, :frame_roi

  def self.from_disk
    Config.new.tap do |new_config|
      f =  'config.json'
      new_config.attributes = JSON.parse File.read(f) if File.exist?(f)
    end
  end

  def to_disk
    File.open('config.json','w') do |file|
      file.puts to_json
    end
  end

  def initialize
    @updated_at = Time.current

    @world_transform = Transform.new.tap do |transform|
      transform.origin_x = 365
      transform.origin_y = 178
      transform.scale = 93
      transform.rotation = 0
    end

    @colors = %w(red green blue).map do |color_name|
      Color.new.tap do |color|
        color.name = color_name
        %w(hue saturation value).each do |key|
          color.send "#{key}=", [0, 255]
        end
      end
    end
  end

  def attributes=(hash)
    new_world_transform = hash.delete 'world_transform'
    world_transform.attributes = new_world_transform if new_world_transform.present?

    @colors = hash.delete('colors').map do |color_attrs|
      Color.new.tap do |new_color|
        new_color.attributes = color_attrs
      end
    end

    hash.each do |key, value|
      send("#{key}=", value)
    end

    @track = Track.new world_transform, layout.split(' ')
    @image_processor = nil
    @updated_at = Time.current
  end

  def set_start_line(left, right, frame_width, frame_height)
    frame_transform = Transform.new.tap do |t|
      t.origin_x = (left.x + right.x) / 2
      t.origin_y = (left.y + right.y) / 2

      angle = Math.atan2 (left.x - right.x), (left.y - right.y)
      t.rotation = ((angle / (Math::PI / 2.0)) * 360) + 270

      width = Math.sqrt((left.x - right.x).abs**2 + (left.y - right.y).abs**2) #91
      t.scale = width * (1/0.6)
    end

    frame_track = Track.new frame_transform, layout.split(' ')
    @frame_roi = frame_track.roi
    binding.pry

    @world_transform = frame_transform
    @world_transform.origin_x -= frame_roi.x
    @world_transform.origin_y -= frame_roi.y

    @image_processor = nil
  end

  def attributes
    instance_values.except 'updated_at', 'track', 'frame_roi'
  end

  def color_names
    colors.map(&:name)
  end

  def image_processor
    @image_processor ||= ImageProcessor.new track, colors
  end
end
