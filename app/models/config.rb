WorldTransform = Struct.new :origin, :scale, :rotation

class Config
  attr_reader :world_transform, :colors, :color_window_on

  def initialize
    @config = YAML.load_file 'config.yml'

    @color_window_on = @config['color_window_on']

    origin = CvPoint.new 356, 178
    scale = 93
    rotation = 0
    @world_transform = WorldTransform.new origin, scale, rotation

    @colors = @config['colors'].map do |color, _|
      hsv_low = CvScalar.new get_attr(color, 'hue', 'low'), get_attr(color, 'saturation', 'low'), get_attr(color, 'value', 'low')
      hsv_high = CvScalar.new get_attr(color, 'hue', 'high'), get_attr(color, 'saturation', 'high'), get_attr(color, 'value', 'high')
      Color.new color, hsv_low, hsv_high
    end
  end

  def color_names
    colors.map(&:name)
  end

  private

  def get_attr(color, name, kind)
    color_attr = @config.dig 'colors', color, name, kind
    default_attr = @config.dig('defaults', name, kind)
    color_attr || default_attr
  end
end
