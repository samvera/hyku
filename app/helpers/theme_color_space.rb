# frozen_string_literal: true

module ThemeColorSpace
  def theme_hue(hex)
    red, green, blue = theme_channels(hex).map { |channel| channel / 255.0 }
    high, low = [red, green, blue].minmax.reverse
    return 0.0 if high == low

    spread = high - low
    sector = case high
             when red then ((green - blue) / spread) % 6
             when green then ((blue - red) / spread) + 2
             else
               ((red - green) / spread) + 4
             end
    (sector * 60) % 360
  end

  def theme_hue_shift(one, two)
    distance = (theme_hue(one) - theme_hue(two)).abs
    [distance, 360 - distance].min
  end

  def theme_hsl(hex)
    red, green, blue = theme_channels(hex).map { |channel| channel / 255.0 }
    high, low = [red, green, blue].minmax.reverse
    lightness = (high + low) / 2
    saturation = high == low ? 0 : (high - low) / (1 - ((2 * lightness) - 1).abs)
    [theme_hue(hex), saturation, lightness]
  end

  def theme_from_hsl(hue, saturation, lightness)
    chroma = (1 - ((2 * lightness) - 1).abs) * saturation
    second = chroma * (1 - (((hue / 60.0) % 2) - 1).abs)
    offset = lightness - (chroma / 2)
    sectors = [[chroma, second, 0], [second, chroma, 0], [0, chroma, second],
               [0, second, chroma], [second, 0, chroma], [chroma, 0, second]]
    theme_hex(sectors[(hue % 360 / 60).floor].map { |value| (value + offset) * 255 })
  end

  def theme_turn_hue(hex, degrees)
    hue, saturation, lightness = theme_hsl(hex)
    theme_from_hsl((hue + degrees) % 360, saturation, lightness)
  end

  private

  def theme_channels(hex)
    hex.to_s.delete('#').scan(/../).map { |pair| pair.to_i(16) }
  end

  def theme_hex(channels)
    format('#%02x%02x%02x', *channels.map { |channel| channel.round.clamp(0, 255) })
  end
end
