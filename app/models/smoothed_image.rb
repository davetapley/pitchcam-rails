class SmoothedImage
  attr_reader :image, :frame_count

  def initialize
    @threshold = CvScalar.new 10, 10, 10
  end

  def add_frame(new_frame)
    if image.nil?
      @frame_count = 1
      @image = new_frame
    else
      new_frame_weight = 1 / frame_count.to_f
      image_weight = 1 - new_frame_weight
      @frame_count += 1
      @image = CvMat.add_weighted image, image_weight, new_frame, new_frame_weight, 0
    end
  end

  def set_threshold(hue, saturation, value)
    @threshold = CvScalar.new hue, saturation, value
  end

  def delete_from(other)
    diff = image.abs_diff other

    low = @threshold

    return diff unless low

    high = CvScalar.new 255, 255, 255
    mask = diff.in_range low, high

    other.clone.set CvColor::Black, mask.not.dilate(nil, 1)
  end
end
