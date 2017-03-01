class Straight
  # Longest side in y axis

  WIDTH = 1
  HEIGHT = 1.64

  def inside?(point)
    0 < point.x && point.x < WIDTH && 0 < point.y && point.y < HEIGHT
  end

  def next_local_origin
    CvPoint2D32f.new 0, HEIGHT
  end

  def position_from_local(point)
    p = point.y / HEIGHT # progress
    d = point.x / WIDTH # drift
    Track::Postition.new p, d
  end

  def local_from_position(position)
    CvPoint2D32f.new (position.d * WIDTH), (position.p * HEIGHT)
  end

  def next_angle
    0
  end

  def outline
    p0 = CvPoint2D32f.new 0, 0
    p1 = CvPoint2D32f.new WIDTH, 0
    p2 = CvPoint2D32f.new WIDTH, HEIGHT
    p3 = CvPoint2D32f.new 0, HEIGHT
    [
      [:line, p0, p1],
      [:line, p1, p2],
      [:line, p2, p3],
      [:line, p3, p0]
    ]
  end

  def progress_line(progress)
    p0 = CvPoint2D32f.new 0, (progress * HEIGHT)
    p1 = CvPoint2D32f.new WIDTH, (progress * HEIGHT)

    [[:line, p0, p1]]
  end
end
