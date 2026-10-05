# frozen_string_literal: true

module Hyku
  ##
  # Limits HTML in IIIF v3 metadata values to what Presentation API 3.0 allows
  # (section 4.5), with every link and image target absolute, since a viewer
  # would otherwise resolve a relative one against its own origin.
  module IiifMetadataHtml
    ALLOWED_TAGS = %w[a b br i img p small span sub sup].freeze
    ALLOWED_ATTRIBUTES = %w[href target rel src alt].freeze
    URL_ATTRIBUTES = { 'a' => 'href', 'img' => 'src' }.freeze

    module_function

    def sanitize(html, base_url:)
      fragment = Nokogiri::HTML.fragment(html)
      URL_ATTRIBUTES.each do |tag, attribute|
        fragment.css("#{tag}[#{attribute}]").each { |node| node[attribute] = absolute_url(node[attribute], base_url) }
      end
      Rails::Html::SafeListSanitizer.new.sanitize(fragment.to_html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).strip
    end

    # For entries built elsewhere, such as IiifPrint's for a work without a profile.
    def sanitize_entries(entries, base_url:)
      Array(entries).map do |entry|
        entry.merge('value' => entry['value'].transform_values { |values| Array(values).map { |value| sanitize(value.to_s, base_url:) } })
      end
    end

    def absolute_url(url, base_url)
      return url if url.blank? || url.match?(/\A[a-z][a-z0-9+.-]*:/i)

      URI.join("#{base_url.to_s.chomp('/')}/", url).to_s
    rescue URI::Error
      url
    end
  end
end
