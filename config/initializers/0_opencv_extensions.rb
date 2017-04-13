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

module CvScalarExtensions
  def inspect
    (0..3).map { |i| self[i] }
  end

  def as_json
    (0..3).map { |i| self[i] }.as_json
  end
end

CvScalar.prepend CvScalarExtensions

module IplImageExtensions
  def load_from_data_uri(uri)
    uri = URI::Data.new uri
    file = Tempfile.new 'image.jpg'
    begin
      file.binmode
      file.write uri.data
      IplImage.load file.path
    ensure
      file.close
      file.unlink
    end
  end
end

IplImage.extend IplImageExtensions
