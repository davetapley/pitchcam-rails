Color = Struct.new :name, :hsv_low, :hsv_high do
  def map(image)
    hsv = image.BGR2HSV
    hsv.in_range(hsv_low, hsv_high).dilate nil, 2
  end
end
