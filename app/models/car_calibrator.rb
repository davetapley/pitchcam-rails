class CarCalibrator
  attr_reader :car_radius, :expected_car_pixel_count, :debug, :smoothed_image

  def initialize(car_radius_world)
    @car_radius = car_radius_world
    @expected_car_pixel_count  = (car_radius_world**2 * Math::PI).round
    @debug = {}
    @smoothed_image = SmoothedImage.new
  end

  def handle_image(diff_mask, image)
    dp = 2
    min_dist = 5
    p1 = 200
    p2 = 10
    r_min = car_radius * 0.8
    r_max = car_radius * 1.2

    hough = diff_mask.hough_circles(CV_HOUGH_GRADIENT, dp, min_dist, p1, p2, r_min, r_max)
    hough.to_a.sort_by! { |circle| (car_radius - circle.radius).abs }
    circle = hough.first

    debug[:circle] = circle ? circle.center : nil
    return unless circle

    center = circle.center
    tl = CvPoint.new center.x - car_radius, center.y - car_radius
    diameter = car_radius * 2
    size = CvSize.new diameter, diameter
    car_image = image.sub_rect(tl, size).BGR2BGRA

    car_mask = CvMat.new diameter, diameter, :cv8uc1, 1
    car_mask.set_zero!
    car_mask.circle! CvPoint.new(diameter / 2, diameter / 2), car_radius, color: CvColor::White, thickness: -1

    car_image.set! CvScalar.new, car_mask.not
    smoothed_image.add_frame car_image
    debug[:frames] = smoothed_image.frame_count
  end

  def smoothed_image_uri
    return 'data:image/png;base64,' unless smoothed_image.present?
    smoothed_image.to_data_uri
  end
end
