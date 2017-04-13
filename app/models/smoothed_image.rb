class SmoothedImage
  attr_reader :image, :frame_count

  delegate :abs_diff, to: :image

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
end
