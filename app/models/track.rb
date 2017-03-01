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

  CAR_RADIUS_TRACK = 0.1

  def initialize(world_transform)
    @car_radius_world = CAR_RADIUS_TRACK * world_transform.scale

    start_origin = world_transform.origin
    angle = 0
    @segments = [Segment.new(0, start_origin, angle, world_transform, Straight)]

    tiles = [Corner, Straight, Corner, Straight, Corner, Straight, Corner]
    tiles.each_with_index do |tile, index|
      prev_segment = segments.last

      origin = prev_segment.next_world_origin
      angle = (angle + prev_segment.next_angle) % (Math::PI * 2)

      segment = Segment.new index + 1, origin, angle, world_transform, tile
      segments << segment

      puts "#{segment.world_to_local origin}"
    end
  end

  def inside?(point)
    segments.any? { |segment| segment.inside? point }
  end

  def render_outline_to(canvas)
    segments.each { |segment| segment.render_outline_to canvas }
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
end
