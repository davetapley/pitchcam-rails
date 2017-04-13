class Segment

  attr_reader :index, :world_origin, :angle, :world_transform, :tile, :bottom_left_world, :mirror_x

  def initialize(index, prev_segment_next_world_origin, angle, mirror_x, world_transform, tile_class)
    @index = index
    @tile = tile_class.new

    @angle = angle
    @mirror_x = mirror_x
    @world_transform = world_transform
    @world_origin = prev_segment_next_world_origin
  end


  def render_outline_to(canvas, color)
    render_to canvas, tile.outline, color

    label_position = local_to_world CvPoint2D32f.new 0, 0
    canvas.circle!(label_position, 4, color: CvColor::Red)
    canvas.put_text!(index.to_s, label_position, CvFont.new(:simplex), CvColor::White)

    #angle_position = local_to_world CvPoint2D32f.new -0.3, -0.5
    #canvas.circle!(angle_position, 2, color: CvColor::Blue)
  end

  def render_mask_to(mask)
    render_to mask, tile.mask
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

    point_x = point.x * (mirror_x ? -1 : 1)
    point_y = point.y

    x_r = (point_x * cos_a) - (point_y * sin_a)
    y_r = (point_y * cos_a) + (point_x * sin_a)

    world_scale = world_transform.scale
    x = (x_r * world_scale) + world_origin.x
    y = (y_r * world_scale) + world_origin.y
    CvPoint.new x.round, y.round
  end

  def render_to(canvas, shapes, color = CvColor::White)
    segment_canvas = canvas.clone

    shapes.each do |type, *points|
      from = local_to_world points[0]

      case type
      when :line
        to = local_to_world points[1]
        segment_canvas.line! from, to, thickness: 2, color: color
      when :arc
        origin = local_to_world points[1]
        radius = points[2] * world_transform.scale
        axes = CvSize.new radius , radius
        angle_deg = (-angle / Math::PI) * 180
        start_angle_deg = mirror_x ? 90 : 0
        end_angle_deg = start_angle_deg + 90
        segment_canvas.ellipse! origin, axes, angle_deg, start_angle_deg, end_angle_deg, thickness: 2, color: color
      when :rectangle
        to = local_to_world points[1]
        tr = local_to_world CvPoint2D32f.new points[0].x, points[1].y
        bl = local_to_world CvPoint2D32f.new points[1].x, points[0].y
        segment_canvas.fill_poly! [[from, tr, to, bl]], color: 255, thickness: -1
      when :circle
        radius = points[1] * world_transform.scale
        color = points[2] == :black ? 0 : 255
        segment_canvas.circle! from, radius, color: color, thickness: -1
      else
        raise "Can't render #{type}"
      end
    end

    segment_mask = CvMat.new canvas.size.height, canvas.size.width, :cv8uc1, 1
    segment_mask.set_zero!
    tl = local_to_world CvPoint2D32f.new(-0.5, -0.5)
    tr = local_to_world CvPoint2D32f.new(0.5, -0.5)
    bl = local_to_world CvPoint2D32f.new(-0.5, 0.5)
    br = local_to_world CvPoint2D32f.new(0.5, 0.5)
    segment_mask.fill_poly! [[tl, tr, br, bl]], color: 255
    segment_canvas.copy canvas, segment_mask
  end
end
