# frozen_string_literal: true

# Presentation helpers shared by the Hyku themes.
module ThemeHelper
  def theme_plain_text(html)
    # strip_tags re-escapes what it returns, and every consumer escapes again on
    # the way out, so an ampersand would reach the reader as &amp;
    CGI.unescapeHTML(strip_tags(CGI.unescapeHTML(html.to_s).gsub('>', '> ')).squish)
  end

  def theme_blurb(text, length:)
    return if text.blank?

    truncate(theme_plain_text(text), length:, separator: ' ')
  end

  def theme_citations(presenter)
    { 'apa' => export_as_apa_citation(presenter),
      'mla' => export_as_mla_citation(presenter),
      'chicago' => export_as_chicago_citation(presenter) }.select { |_style, text| text.present? }
  end

  def theme_viewer?(presenter)
    presenter.video_embed_viewer? ||
      (presenter.representative_id.present? && presenter.representative_presenter.present?)
  end

  def theme_luminance(hex)
    channels = hex.to_s.delete('#').scan(/../).map { |pair| pair.to_i(16) / 255.0 }
    return 0 unless channels.size == 3

    channels.zip([0.2126, 0.7152, 0.0722]).sum do |channel, weight|
      weight * (channel <= 0.03928 ? channel / 12.92 : (((channel + 0.055) / 1.055)**2.4))
    end
  end

  # How much of a brand colour to keep when lifting it for a dark surface: the
  # design value unless that leaves it under the contrast floor.
  def theme_brand_mix(hex)
    return 55 unless hex.to_s.delete('#').length == 6

    55.step(5, -5) do |percent|
      lifted = hex.to_s.delete('#').scan(/../).map do |pair|
        ((pair.to_i(16) * percent) + (255 * (100 - percent))) / 100
      end
      return percent if theme_luminance(format('#%02x%02x%02x', *lifted)) >= 0.31
    end
  end

  def theme_readable_ink(hex)
    # black clears 4.5:1 from 0.175 up and white to 0.183, so the crossover
    # leaves no accent without a readable ink
    theme_luminance(hex) > 0.175 ? '#000000' : '#ffffff'
  end

  def theme_thumbnail_url(document, default: :work)
    indexed = document.try(:[], 'thumbnail_path_ss').presence
    return indexed if indexed && !indexed.include?('/assets/')

    return Site.instance.default_collection_image&.url || image_path('default.png') if default == :collection

    Site.instance.default_work_image&.url || indexed || image_path('default.png')
  end
end
