# frozen_string_literal: true

# OVERRIDE Hyrax to honor the skip_file_metadata_solr_indexing account setting - FileSetIndexer already has these fields.
module Hyrax
  module Listeners
    module MetadataIndexListenerDecorator
      def on_file_metadata_updated(event)
        return if current_account&.skip_file_metadata_solr_indexing
        super
      end

      def on_file_metadata_deleted(event)
        return if current_account&.skip_file_metadata_solr_indexing
        super
      end

      private

      def current_account
        Account.find_by(tenant: Apartment::Tenant.current)
      end
    end
  end
end

Hyrax::Listeners::MetadataIndexListener.prepend(Hyrax::Listeners::MetadataIndexListenerDecorator)
