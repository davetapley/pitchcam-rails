class TrackMask < Struct.new :track
  def mask_image(image)
    image.clone.set CvColor::White, mask(image)
  end

  def mask(image)
    height = image.size.height
    width = image.size.width
    return @cached_mask if height == @cached_height && width == @cached_width

    @cached_mask = CvMat.new(height, width, :cv8uc1, 1).tap do |mask|
      mask.set_zero!
      track.segments.each { |segment| segment.render_mask_to mask }
      mask.not!

      @cached_width = width
      @cached_height = height
    end
  end
end
