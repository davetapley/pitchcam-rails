require 'opencv'
include OpenCV

module CvPointExtensions
  def inspect
    "(#{ x.round 2 }, #{ y.round 2 })"
  end

  def to_json
    { x: x, y: y }.to_json
  end
end

CvPoint.prepend CvPointExtensions
CvPoint2D32f.prepend CvPointExtensions
