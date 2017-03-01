class Segment

  attr_reader :index, :world_origin, :angle, :world_transform, :tile, :bottom_left_world

  def initialize(index, world_origin, angle, world_transform, tile_class)
    @index = index
    @world_origin = world_origin
    @angle = angle
    @world_transform = world_transform
    @tile = tile_class.new
  end


  def render_outline_to(canvas)
    render_to canvas, tile.outline

    label_position = local_to_world CvPoint2D32f.new 0.5, 0.5
    canvas.put_text!(index.to_s, label_position, CvFont.new(:simplex), CvColor::White)
  end

  def render_progress_to(canvas, color, position)
    render_to canvas, tile.progress_line(position.p), color
  end

  def inside?(point)
    local_point = world_to_local point
    tile.inside? local_point
  end

  def next_world_origin
    local_to_world tile.next_local_origin
  end

  def next_angle
    tile.next_angle
  end

  def position_from_world(point)
    local_point = world_to_local point
    tile.position_from_local local_point
  end

  def world_from_position(position)
    local_to_world tile.local_from_position(position)
  end

  def world_to_local(point)
    cos_a = Math.cos angle
    sin_a = Math.sin angle

    world_scale = world_transform.scale
    x = (point.x - world_origin.x) / world_scale
    y = (point.y - world_origin.y) / world_scale

    x_r = (x * cos_a) - (y * sin_a)
    y_r = (y * cos_a) + (x * sin_a)

    CvPoint2D32f.new x_r, y_r
  end

  def local_to_world(point)
    cos_a = Math.cos -angle
    sin_a = Math.sin -angle

    x_r = (point.x * cos_a) - (point.y * sin_a)
    y_r = (point.y * cos_a) + (point.x * sin_a)

    world_scale = world_transform.scale
    x = (x_r * world_scale) + world_origin.x
    y = (y_r * world_scale) + world_origin.y
    CvPoint.new x, y
  end

  def render_to(canvas, shapes, color = CvColor::White)
    shapes.each do |type, *points|
      from = local_to_world points[0]

      case type
      when :line
        to = local_to_world points[1]
        canvas.line! from, to, thickness: 1, color: color
      when :arc
        origin = local_to_world points[1]
        radius = points[2] * world_transform.scale
        axes = CvSize.new radius, radius
        angle_deg = (-angle / Math::PI) * 180
        canvas.ellipse! origin, axes, angle_deg, 0, 90, thickness: 1, color: color
      else
        raise "Can't render #{type}"
      end

    end
  end
end
