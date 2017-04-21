class CarTracker
  def initialize(color)
    @color = color
    @on_track = false
    @positions = []
  end

  def on_track!(position)
    @positions << position
    @on_track = true
  end

  def off_track!
    @on_track = false
  end

  def last_position
    @positions.last
  end

  def render_last_position_to(image)
    return unless last_position

    image.crosshair! last_position, @color.cv_color
    image.put_text! @color.name, CvPoint.new(0, last_position.y), CvFont.new(:simplex), @color.cv_color
  end
end
