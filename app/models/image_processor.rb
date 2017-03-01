class ImageProcessor

  attr_reader :track, :colors, :colors_world_positions, :colors_track_positions

  def initialize(track, colors)
    @track = track
    @colors = colors

    color_names = colors.map(&:name)
    @colors_world_positions = Hash[color_names.map { |color| [color, nil] }]
    @colors_track_positions = Hash[color_names.map { |color| [color, nil] }]

    @dirty_start = nil
  end

  def handle_image(image)
    @dirty_colors = [] if @dirty_start.nil?

    colors.each do |color|
      hough = color.map(image).hough_circles CV_HOUGH_GRADIENT, 2, 5, 200, 40
      hough = hough.to_a.reject { |circle| circle.radius > track.car_radius_world * 1.5 }

      if hough.size > 0
        circle = hough.first
        new_world_position = circle.center
        #puts "#{color.name}\tworld\t#{new_world_position}"

        on_track = track.inside? circle.center
        if on_track
          previous_world_position = colors_world_positions[color]
          new_track_position = track.position_from_world new_world_position

          if previous_world_position.nil?
            mark_dirty color, new_world_position, new_track_position
          else
            delta_x = (new_world_position.x - previous_world_position.x).abs
            delta_y = (new_world_position.y - previous_world_position.y).abs
            delta = Math.sqrt(delta_x + delta_y)
            mark_dirty color, new_world_position, new_track_position if delta > 4
          end
        else
          previous_track_position = colors_track_positions[color]
          mark_dirty color, new_world_position, nil unless previous_track_position.nil?
        end
      end
    end

    if @dirty_colors.size > 0
      @dirty_start ||= Time.now

      dirty_time = Time.now - @dirty_start
      if dirty_time > 2.0
        @dirty_start = nil
        return @dirty_colors
      else
        return []
      end
    else
      return []
    end
  end

  private

  def mark_dirty(color, world_position, track_position)
    colors_world_positions[color] = world_position
    colors_track_positions[color] = track_position
    @dirty_colors << [color.name, track_position]
  end
end
