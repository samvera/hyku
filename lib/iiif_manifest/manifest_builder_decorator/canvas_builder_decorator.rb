# frozen_string_literal: true

# OVERRIDE IIIFManifest v1.3.1 to use the parent's title as the label instead of the filename

module IIIFManifest
  module ManifestBuilderDecorator
    module CanvasBuilderDecorator
      private

      def apply_record_properties
        canvas['@id'] = path
        canvas.label = record['parent_title_tesim']&.first || record.to_s
      end
    end
  end
end

IIIFManifest::ManifestBuilder.prepend(IIIFManifest::ManifestBuilderDecorator)
IIIFManifest::ManifestBuilder::CanvasBuilder.prepend(IIIFManifest::ManifestBuilderDecorator::CanvasBuilderDecorator)
