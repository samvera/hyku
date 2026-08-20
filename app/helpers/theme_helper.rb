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

  def theme_thumbnail_url(document, default: :work)
    indexed = document.try(:[], 'thumbnail_path_ss').presence
    return indexed if indexed && !indexed.include?('/assets/')

    return Site.instance.default_collection_image&.url || image_path('default.png') if default == :collection

    Site.instance.default_work_image&.url || indexed || image_path('default.png')
  end
end
