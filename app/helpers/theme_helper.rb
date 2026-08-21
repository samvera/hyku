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

  # FeaturedWorkList and FeaturedCollectionList build their presenters with
  # ability = nil, so anything rendering them must re-check read access.
  def theme_readable_ids(ids)
    return [] if ids.empty?

    (_, documents) = @search_service.fetch(ids, rows: ids.size, fl: 'id')

    documents.map(&:id)
  end

  def theme_thumbnail_url(document, default: :work)
    indexed = document.try(:[], 'thumbnail_path_ss').presence
    return indexed if indexed && !indexed.include?('/assets/')

    return Site.instance.default_collection_image&.url || image_path('default.png') if default == :collection

    Site.instance.default_work_image&.url || indexed || image_path('default.png')
  end
end
