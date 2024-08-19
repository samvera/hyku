# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 to change `&amp;`	to `&` in the Universal Viewer

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
    # @return [String] the String that gets unescaped since Loofah is too aggressive for example
    #   it changes to `&` to `&amp;` which will be displayed in the Universal Viewer and manifest
    # @see #sanitize_value
    def loof(text)
      CGI.unescapeHTML(Loofah.fragment(text.to_s).scrub!(:prune).to_s)
    end

    def sanitize_v3(hash:, presenter:, solr_doc_hits:)
      returning_hash = super
      returning_hash['viewingHint'] = 'paged'
      returning_hash
    end
  end
end

Hyrax::ManifestBuilderService.prepend(Hyrax::ManifestBuilderServiceDecorator)
