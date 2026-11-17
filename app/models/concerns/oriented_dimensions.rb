# frozen_string_literal: true

# Characterization stores image width/height as stored in the file, ignoring EXIF orientation.
# When riiif autorotates, tiles are rotated, so swap the axes for 90/270 degree orientations
# (the FITS orientation text for every such tag contains "90°").
module OrientedDimensions
  def width
    axes_swapped? ? self['height_is'] : super
  end

  def height
    axes_swapped? ? self['width_is'] : super
  end

  private

  def axes_swapped?
    Riiif.respond_to?(:autorotate?) && Riiif.autorotate? && Array(orientation).any? { |value| value.to_s.include?('90°') }
  end
end
