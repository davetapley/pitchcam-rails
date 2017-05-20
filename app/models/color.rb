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

  def to_s
    name
  end

  def cv_color
    "CvColor::#{ name.titleize }".constantize
  end

  def calibrator(car_radius_world)
    @calibrator ||= CarCalibrator.new car_radius_world
  end

  def reset_calibrator
    @calibrator = nil
  end

  private

  def hsv_low_cv_scalar
    CvScalar.new hue.first, saturation.first, value.first
  end

  def hsv_high_cv_scalar
    CvScalar.new hue.last, saturation.last, value.last
  end

end
