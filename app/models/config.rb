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
  attr_reader :updated_at, :world_transform, :colors, :color_window_on, :video_mode, :null_image, :null_image_threshold

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

    @null_image_threshold = CvScalar.new 0, 20, 50

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
    @track_mask = nil
    @car_finder = nil

    new_colors = hash.delete 'colors'
    if new_colors.present?
      @colors = new_colors.map do |color_attrs|
        Color.new.tap do |new_color|
          new_color.attributes = color_attrs
        end
      end
    end

    hash.delete('null_image_threshold').tap do |t|
      @null_image_threshold = CvScalar.new(*t) if t
    end

    hash.each do |key, value|
      send("#{key}=", value)
    end

    @updated_at = Time.current
  end

  def attributes
    instance_values.except 'updated_at', 'track', 'track_mask', 'car_finder', 'null_image', 'video_mode'
  end

  def color_names
    colors.map(&:name)
  end

  def track
    @track ||= Track.new world_transform, layout.split(' ')
  end

  def track_mask
    @track_mask ||= TrackMask.new track
  end

  def car_finder
    @car_finder ||= CarFinder.new colors, track.car_radius_world
  end

  def start_null_image_capture
    @null_image = SmoothedImage.new
    @video_mode = :capturing_null_image
  end

  def end_null_image_capture
    @video_mode = nil
  end
end
