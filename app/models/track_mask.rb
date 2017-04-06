class TrackMask < Struct.new :track
  def mask_image(image)
    mask = mask image.size.height, image.size.width
    image.clone.set CvColor::White, mask
  end

  def mask(height, width)
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
