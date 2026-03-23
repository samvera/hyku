# frozen_string_literal: true

# OVERRIDE: Hyrax 5.x - Guard against Wings::Valkyrie::MetadataAdapter when
# Wings is not loaded (e.g. HYRAX_SKIP_WINGS=true / disable_wings).  The
# upstream `defined?(Wings)` check can return true even when the Wings engine
# was never required, which causes a NameError on Wings::Valkyrie.

module Hyrax
  module DownloadsControllerDecorator
    private

    def file_set_parent(file_set_id)
      wings_adapter = begin
        defined?(Wings::Valkyrie::MetadataAdapter) && Wings::Valkyrie::MetadataAdapter
                      rescue NameError
                        nil
      end

      file_set = if wings_adapter && Hyrax.metadata_adapter.is_a?(wings_adapter)
                   Hyrax.query_service.find_by_alternate_identifier(
                     alternate_identifier: file_set_id,
                     use_valkyrie: Hyrax.config.use_valkyrie?
                   )
                 else
                   Hyrax.query_service.find_by(id: file_set_id)
                 end

      @parent ||=
        case file_set
        when Hyrax::Resource
          Hyrax.query_service.find_parents(resource: file_set).first
        else
          file_set.parent
        end
    end
  end
end

Hyrax::DownloadsController.prepend(Hyrax::DownloadsControllerDecorator)
