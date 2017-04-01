require 'opencv'
include OpenCV

class WorldTransform
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
  attr_reader :updated_at, :world_transform, :colors, :color_window_on

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

    @world_transform = WorldTransform.new.tap do |transform|
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
    @track = nil
    @image_processor = nil

    new_colors = hash.delete 'colors'
    if new_colors.present?
      @colors = new_colors.map do |color_attrs|
        Color.new.tap do |new_color|
          new_color.attributes = color_attrs
        end
      end
    end

    hash.each do |key, value|
      send("#{key}=", value)
    end

    @updated_at = Time.current
  end

  def attributes
    instance_values.except 'updated_at', 'track', 'image_processor'
  end

  def color_names
    colors.map(&:name)
  end

  def track
    @track ||= Track.new world_transform, layout.split(' ')
  end

  def image_processor
    @image_processor ||= ImageProcessor.new colors, track.car_radius_world
  end
end
