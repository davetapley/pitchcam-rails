class Track
  Postition = Struct.new :p, :d do
    def segment_index
      p.floor
    end

    def to_segment_local
      Postition.new p.modulo(1), d
    end

    def to_track_at(index)
      Postition.new (index + p), d
    end

    def to_local
      Postition.new (p % 1), d
    end

    def to_s
      "#{segment_index}\t#{to_local.p.round 2}\t#{d.round 2}"
    end
  end

  attr_reader :segments, :car_radius_world

  CAR_RADIUS_TRACK = 0.078

  def initialize(world_transform, layout)
    @car_radius_world = CAR_RADIUS_TRACK * world_transform.scale

    start_origin = world_transform.origin
    angle = (world_transform.rotation / 180.0) * Math::PI

    raise 'First track direction must be straight' unless tile_for_direction(layout.first) == Straight
    @segments = [Segment.new(0, start_origin, angle, false, world_transform, Straight)]

    layout.from(1).each_with_index do |direction, index|
      prev_segment = segments.last
      tile = tile_for_direction direction

      angle += prev_segment.next_angle
      angle += Math::PI if prev_segment.tile.is_a?(Corner) && prev_segment.mirror_x
      angle = angle % (Math::PI * 2)

      mirror_x =  %w(t l).include? direction.downcase
      segment = Segment.new index + 1, prev_segment.next_world_origin, angle, mirror_x, world_transform, tile
      segments << segment
    end
  end

  def inside?(point)
    segments.any? { |segment| segment.inside? point }
  end

  def render_outline_to(canvas, color)
    segments.each { |segment| segment.render_outline_to canvas, color }
  end

  def render_progress_to(canvas, color, position)
    segment = segments[position.segment_index]
    segment.render_progress_to canvas, color, position.to_local
  end

  def position_from_world(point)
    index = segments.find_index { |segment| segment.inside? point }
    return nil unless index

    segment_position = segments[index].position_from_world point
    raise "Segment progress should never be above 1" if segment_position.p >= 1
    segment_position.to_track_at index
  end

  def world_from_position(position)
    segment = segments[position.segment_index]
    segment.world_from_position position.to_segment_local
  end

  private

  def tile_for_direction(direction)
    case direction.downcase
    when 's', 't'
      Straight
    when 'l', 'r'
      Corner
    else
      raise "#{ direction  } is not a track layout direction"
    end
  end
end
