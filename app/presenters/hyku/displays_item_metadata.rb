# frozen_string_literal: true

module Hyku
  module DisplaysItemMetadata
    attr_writer :item_metadata

    def item_metadata
      return if @item_metadata.blank?
      return @item_metadata unless Hyrax.config.iiif_manifest_factory == ::IIIFManifest::V3::ManifestFactory

      @item_metadata.map do |field|
        label = field['label']
        value = field['value']
        { 'label' => label.is_a?(Hash) ? label : ::IIIFManifest::V3::ManifestBuilder.language_map(label),
          'value' => value.is_a?(Hash) ? value : ::IIIFManifest::V3::ManifestBuilder.language_map(Array(value).map(&:to_s)) }
      end
    end
  end
end
