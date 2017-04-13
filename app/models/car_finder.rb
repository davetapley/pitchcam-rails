class CarFinder
  attr_reader :colors, :car_radius, :car_postion_tolerance,
    :expected_car_pixel_count, :expected_total_pixel_count,
    :colors_positions, :colors_debug,
    :dirty_at, :dirty_colors, :min_time_for_new_position

  def initialize(colors, car_radius_world)
    @colors = colors

    @car_radius = car_radius_world
    @expected_car_pixel_count  = (car_radius_world**2 * Math::PI).round
    @expected_total_pixel_count = expected_car_pixel_count * colors.count

    @car_postion_tolerance = 4
    @min_time_for_new_position = 5.seconds

    @colors_positions = Hash.new OffTrack.new
    @colors_debug = Hash.new { |hash,key| hash[key] = ColorDebug.new }

    @dirty_colors = Set.new
    @dirty_at = nil
  end

  def handle_image(image)
    colors.each { |color| update_color image, color }
    new_positions
  end

  ColorDebug = Struct.new :pixel_count, :circle_count

  module TimeDifferentiatable
    attr_reader :at

    def initialize(*args)
      @at = Time.current
      super *args
    end

    def different_in_time?(other)
      (at - other.at).abs > 2.seconds
    end
  end

  class OnTrack
    prepend TimeDifferentiatable

    attr_reader :position
    delegate :x, :y, to: :position

    def initialize(car_postion_tolerance, circle)
      @car_postion_tolerance = car_postion_tolerance
      @position = circle.center
    end

    def different_in_space?(other)
      case other
      when OnTrack
        delta_x = (x - other.x).abs
        delta_y = (y - other.y).abs
        delta = Math.sqrt(delta_x + delta_y)
        delta > @car_postion_tolerance
      else
        true
      end
    end

    def to_point
      position
    end
  end

  class OffTrack
    prepend TimeDifferentiatable

    def different_in_space?(other)
      !other.is_a?(OffTrack)
    end

    def to_point
      nil
    end
  end

  private

  def update_color(image, color)
    map = color.hsv_map image

    pixel_count = map.count_non_zero
    colors_debug[color].pixel_count = pixel_count

    #return unless pixel_count.between? (expected_car_pixel_count * 0.2), (expected_car_pixel_count * 1.2)

    dp = 2
    min_dist = 5
    p1 = 200
    p2 = 10
    r_min = car_radius * 0.8
    r_max = car_radius * 1.2

    hough = map.hough_circles(CV_HOUGH_GRADIENT, dp, min_dist, p1, p2, r_min, r_max)
    hough.to_a.sort_by! { |circle| (car_radius - circle.radius).abs }

    colors_debug[color].circle_count = hough.size

    previous_position = colors_positions[color]
    new_position = hough.empty? ? OffTrack.new : OnTrack.new(car_postion_tolerance, hough.first)

    different_in_time = previous_position.different_in_time? new_position
    different_in_space = previous_position.different_in_space? new_position

    if different_in_time && different_in_space
      dirty_colors.add color
      colors_positions[color] = new_position
    end
  end

  def new_positions
    return [] unless dirty_colors.size > 0

    @dirty_at ||= Time.now
    return [] unless dirty_at < min_time_for_new_position.ago

    new_positions = colors_positions.slice dirty_colors

    @dirty_at = nil
    @dirty_colors = Set.new

    return new_positions
  end
end
