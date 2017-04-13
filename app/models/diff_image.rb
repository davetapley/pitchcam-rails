class DiffImage
  attr_reader :base, :other, :threshold

  def initialize(base, other, threshold)
    @base = base
    @other = other
    @threshold = threshold
  end

  def diff
    @diff ||= base.BGR2HSV.abs_diff other.BGR2HSV
  end

  def mask
    @mask ||= diff.in_range(threshold, CvScalar.new(255, 255, 255)).dilate(nil, 1)
  end

  def cleaned
    @cleaned ||= other.clone.set CvColor::Black, mask.not
  end
end

