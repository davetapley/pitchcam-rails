class Corner
  WALL_WIDTH = 0.06
  INNER = -0.31
  OUTER = 0.31 - WALL_WIDTH
  WIDTH = 0.62 - WALL_WIDTH

  # Turning from y = -0.5 to x = -0.5, origin at x = -0.5, y = -0.5

  def inside?(point)
    # Inside bounding square?
    return false unless -0.5 < point.x && point.x < 0.5 && -0.5 < point.y && point.y < 0.5

    # And inside outer circle?
    return false unless inside_circle? point, 0.6

    # But not inside inner circle?
    return false if inside_circle? point, 0.3

    true
  end

  def next_local_origin
    CvPoint2D32f.new -1, 0
  end

  def next_angle
    -(Math::PI / 2.0)
  end

  def position_from_local(point)
    # http://stackoverflow.com/a/839931/21115
    angle = Math.atan2 point.x + 0.5, point.y + 0.5
    p = 1 - (angle / (Math::PI / 2.0)) # progress

    d_h = Math.sqrt((point.x + 0.5)**2 + (point.y + 0.5)**2) - INNER
    d =  d_h / WIDTH

    Track::Postition.new p, d
  end

  def local_from_position(position)
    # http://stackoverflow.com/a/839931/21115
    angle = (position.p) * (Math::PI / 2.0)
    d_x = Math.cos angle
    d_y = Math.sin angle

    r = INNER + (position.d * WIDTH)
    x = r * d_x # TODO this is wrong?
    y = r * d_y # should be multiplying earlier?

    CvPoint2D32f.new x - 0.5, y - 0.5
  end

  def outline
    p0 = CvPoint2D32f.new INNER, -0.5
    p1 = CvPoint2D32f.new OUTER, -0.5
    p2 = CvPoint2D32f.new -0.5, OUTER
    p3 = CvPoint2D32f.new -0.5, INNER

    pO = CvPoint2D32f.new -0.5, -0.5

    [
      [:line, p0, p1], # y = - 0.5
      [:line, p2, p3], # x = - 0.5
      [:arc, p1, pO,  0.5 + INNER + WIDTH], # outer
      [:arc, p0, pO, 0.5 + INNER]  # inner
    ]
  end

  def mask
    pO = CvPoint2D32f.new -0.5, -0.5
    [
      [:circle, pO, 0.5 + INNER + WIDTH], # outer
      [:circle, pO, 0.5 + INNER, :black]  # inner
    ]
  end

  def progress_line(progress)
    angle = progress * (Math::PI / 2.0)

    d_x = Math.cos angle
    d_y = Math.sin angle

    p0 = CvPoint2D32f.new X_LOW + (d_x * INNER), d_y * INNER
    p1 = CvPoint2D32f.new X_LOW + (d_x * OUTER), d_y * OUTER
    [[:line, p0, p1]]
  end

  private

  def inside_circle?(point, radius)
    ((point.x + 0.5)**2) + ((point.y + 0.5)**2) < radius**2
  end
end
