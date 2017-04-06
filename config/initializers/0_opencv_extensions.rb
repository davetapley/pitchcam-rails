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

module CvMatExtensions
  def to_data_uri
    tmp_file =  'tmp/output.png'
    save_image tmp_file
    output_encoded = Base64.strict_encode64 File.open(tmp_file, 'rb').read
    "data:image/png;base64,#{output_encoded}"
  end
end

CvMat.prepend CvMatExtensions
