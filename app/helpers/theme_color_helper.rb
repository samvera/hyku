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

  # Lift a brand color toward white until it clears the small-text floor
  # against the surface it will actually sit on, rather than against an
  # absolute luminance target the surface may not respect.
  def theme_brand_mix_on(hex, surface)
    return 55 unless hex.to_s.delete('#').length == 6

    55.step(5, -5) do |percent|
      return percent if theme_contrast(theme_lift(hex, percent), surface) >= 4.5
    end
    5
  end

  def theme_contrast(one, two)
    high, low = [theme_luminance(one), theme_luminance(two)].minmax.reverse

    (high + 0.05) / (low + 0.05)
  end

  def theme_lift(hex, percent)
    return hex.to_s unless hex.to_s.delete('#').length == 6

    channels = hex.to_s.delete('#').scan(/../).map do |pair|
      ((pair.to_i(16) * percent) + (255 * (100 - percent))) / 100
    end

    format('#%02x%02x%02x', *channels)
  end

  def theme_ground_for(hex, ink_alpha, fallback)
    theme_contrast(theme_lift(hex, 100 - ink_alpha), hex) >= 4.5 ? hex : fallback
  end

  def theme_readable_ink(hex)
    # black clears 4.5:1 from 0.175 up and white to 0.183, so the crossover
    # leaves no accent without a readable ink
    theme_luminance(hex) > 0.175 ? '#000000' : '#ffffff'
  end
end
