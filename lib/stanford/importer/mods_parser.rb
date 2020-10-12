# frozen_string_literal: true

module Stanford
  module Importer
    # Encapsulate Stanford specific logic here.
    # Specifically:
    #  - MODS don't have encoded identifiers. Extract one from the filename.
    class ModsParser < ::Importer::ModsParser
      def collection_attributes
        super.merge(identifier).merge(open_access)
      end

      def record_attributes
        super.merge(identifier).merge(open_access)
      end

      # This gets the properties about a collection from a work.
      # these are used to create a collection if one isn't found.
      # Add the id column to the collection identifiers because
      # we aren't using any external identifiers (the :identifier field)
      def collection
        col_attrs = super
        col_attrs.merge(id: col_attrs[:identifier].first).merge(open_access)
      end

      # The collection_id is a purl.stanford.edu uri. We'll just take the path segment as the id.
      def collection_id
        super.map { |url| URI(url).path.sub('/', '') }
      end

      private

        def identifier
          id = File.basename(filename, '.mods').sub(/\Adruid_/, '')
          { identifier: Array.wrap(id), id: id }
        end

        def open_access
          { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        end
    end
  end
end
