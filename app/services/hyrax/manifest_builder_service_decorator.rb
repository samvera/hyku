# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 and IiifPrint v3.1.1
#   - change `&amp;` to `&` in the Universal Viewer
#   - never unescape scrubbed manifest strings, so escaped markup never becomes a tag
#     (Hyrax's deep_sanitize, IiifPrint's canvas labels in sanitize_v3)
#   - mark v3 manifests as paged, unless their pages carry file set metadata

module Hyrax
  module ManifestBuilderServiceDecorator
    private

    ##
    # @return [Hash<Array>] the Hash to be used by "label" to change `&amp;`	to `&`
    # @see #loof
    def sanitize_value(text)
      return loof(text) unless text.is_a?(Hash)
      text[text.keys.first] = text.values.flatten.map { |value| loof(value) }
      text
    end

    ##
    # @return [String] the text scrubbed, with `&amp;` shown as `&` rather than
    #   left for the Universal Viewer to display literally
    # @see #sanitize_value
    def loof(text)
      Loofah.fragment(text.to_s).scrub!(:prune).to_s.gsub('&amp;', '&')
    end

    # OVERRIDE the String branch, which unescaped after scrubbing
    def deep_sanitize(obj)
      obj.is_a?(String) ? loof(obj) : super
    end

    def sanitize_v3(hash:, presenter:, solr_doc_hits:)
      # OVERRIDE IiifPrint unescapes canvas labels after sanitize_value, turning
      # escaped text into markup, so scrub each label as it was before that
      labels = Array(hash['items']).to_h { |canvas| [canvas['id'], Array(canvas.dig('label', 'none')).dup] }
      returning_hash = super
      returning_hash['items']&.each do |canvas|
        canvas['label']['none'] = labels[canvas['id']].map { |text| loof(text) } if canvas.dig('label', 'none')
      end
      # OVERRIDE
      mark_paged(returning_hash, presenter)
    end

    # Facing pages would show two pages' file set metadata in the viewer's one
    # panel, so a manifest whose pages carry their own opens one page at a time.
    def mark_paged(hash, presenter)
      hash['viewingHint'] = 'paged' unless presenter.try(:file_set_pages?)
      hash
    end
  end
end

Hyrax::ManifestBuilderService.prepend(Hyrax::ManifestBuilderServiceDecorator)

# OVERRIDE IiifPrint 3.1.0 - IiifPrint's ManifestBuilderServiceDecorator flattens
# child works, sanitizes canvas labels, and overwrites item_metadata, all of which
# conflict with Ranges. Bypass its entire manifest_for when the feature is active
# and let the iiif_manifest gem (which natively supports ranges and item_metadata)
# build the manifest directly.
module Hyrax
  module ManifestBuilderServiceRangesDecorator
    def manifest_for(presenter:)
      return super unless Flipflop.iiif_ranges?

      manifest = manifest_factory.new(presenter).to_h
      mark_paged(deep_sanitize(JSON.parse(manifest.to_json)), presenter)
    end
  end
end

Hyrax::ManifestBuilderService.prepend(Hyrax::ManifestBuilderServiceRangesDecorator)
