class Straight
  # Longest side in y axis

  LEFT = -0.3
  RIGHT = 0.3
  WIDTH = 0.6
  FRONT = -0.5
  BACK = 0.5
  HEIGHT = 1

  def inside?(point)
    LEFT < point.x && point.x < RIGHT && FRONT < point.y && point.y < BACK
  end

  def next_local_origin
    CvPoint2D32f.new 0, 1
  end

  def position_from_local(point)
    p = (point.y - FRONT) / HEIGHT # progress
    d = (point.x - LEFT) / WIDTH # drift
    Track::Postition.new p, d
  end

  def local_from_position(position)
    CvPoint2D32f.new (position.d * WIDTH) + LEFT, (position.p * HEIGHT) + FRONT
  end

  def next_angle
    0
  end

  def outline
    p0 = CvPoint2D32f.new LEFT, FRONT
    p1 = CvPoint2D32f.new RIGHT, FRONT
    p2 = CvPoint2D32f.new RIGHT, BACK
    p3 = CvPoint2D32f.new LEFT, BACK
    [
      [:line, p0, p1],
      [:line, p1, p2],
      [:line, p2, p3],
      [:line, p3, p0]
    ]
  end

  def mask
    p0 = CvPoint2D32f.new LEFT, FRONT
    p1 = CvPoint2D32f.new RIGHT, BACK
    [[:rectangle, p0, p1]]
  end

  def progress_line(progress)
    p0 = CvPoint2D32f.new LEFT, (progress * HEIGHT) + FRONT
    p1 = CvPoint2D32f.new RIGHT, (progress * HEIGHT) + FRONT

    [[:line, p0, p1]]
  end
end
