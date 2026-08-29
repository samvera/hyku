# frozen_string_literal: true

# Color math shared by the themes: luminance, contrast, and the lifts that
# keep tenant-set brand colors legible on the surfaces they land on.
module ThemeColorHelper
  def theme_luminance(hex)
    channels = hex.to_s.delete('#').scan(/../).map { |pair| pair.to_i(16) / 255.0 }
    return 0 unless channels.size == 3

    channels.zip([0.2126, 0.7152, 0.0722]).sum do |channel, weight|
      weight * (channel <= 0.03928 ? channel / 12.92 : (((channel + 0.055) / 1.055)**2.4))
    end
  end

  # How much of a brand color to keep when lifting it for a dark surface: the
  # design value unless that leaves it under the contrast floor.
  def theme_brand_mix(hex)
    return 55 unless hex.to_s.delete('#').length == 6

    55.step(5, -5) do |percent|
      return percent if theme_luminance(theme_lift(hex, percent)) >= 0.31
    end
  end

  # Lift a brand colour toward white until it clears the small-text floor
  # against the surface it will actually sit on, rather than against an
  # absolute luminance target the surface may not respect.
  def theme_readable_ink(hex)
    # black clears 4.5:1 from 0.175 up and white to 0.183, so the crossover
    # leaves no accent without a readable ink
    theme_luminance(hex) > 0.175 ? '#000000' : '#ffffff'
  end
end
