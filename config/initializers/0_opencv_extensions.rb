require 'opencv'
include OpenCV

module CvPointExtensions
  def inspect
    "(#{ x.round 2 }, #{ y.round 2 })"
  end

  def as_json(opts)
    { x: x, y: y }.as_json opts
  end
end

CvPoint.prepend CvPointExtensions
CvPoint2D32f.prepend CvPointExtensions
