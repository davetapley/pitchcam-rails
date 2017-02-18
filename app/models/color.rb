require "opencv"

class Color
  include OpenCV
  include ActiveModel::Serializers::JSON

  attr_accessor :name, :hue, :saturation, :value

  def hsv_map(image)
    hsv = image.BGR2HSV
    hsv.in_range(hsv_low_cv_scalar, hsv_high_cv_scalar).dilate nil, 2
  end

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    instance_values
  end

  private

  def hsv_low_cv_scalar
    CvScalar.new hue.first, saturation.first, value.first
  end

  def hsv_high_cv_scalar
    CvScalar.new hue.last, saturation.last, value.last
  end
end
