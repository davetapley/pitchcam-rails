class CarTracker
  def initialize(color)
    @color = color
    @on_track = false
    @positions = []
  end

  def on_track?
    @on_track
  end

  def update!(position)
    if position.is_a? CarFinder::OnTrack
      if @positions.empty? || on_track? || close_to_last_position?(position)
        @positions << position
        @on_track = true
      end
    else
      @on_track = false
    end
  end

  def last_position
    @positions.last
  end

  def render_last_position_to(image)
    return unless last_position && last_position.is_a?(CarFinder::OnTrack)

    point = last_position.to_point
    image.crosshair! point, @color.cv_color
    text = "#{ @color.name } #{ on_track? ? '' : '?' }"

    label_position = case @color.name
                     when 'blue'
                       CvPoint.new image.columns - 100, point.y
                     when 'orange'
                       CvPoint.new point.x, image.rows - 20
                     else
                       CvPoint.new 0, point.y
                     end

    image.put_text! text, label_position, CvFont.new(:simplex, thickness: 2), @color.cv_color
  end

  private

  def close_to_last_position?(position)
    !position.different_in_space?(last_position)
  end
end
