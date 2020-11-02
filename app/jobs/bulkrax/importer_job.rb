# NOTE(bkiahstroud): Override file from Bulkrax 2d247ee1eb20
# NOTE(bkiahstroud): Add custom method to #import
# frozen_string_literal: true

module Bulkrax
  class ImporterJob < ApplicationJob
    queue_as :import

    def perform(importer_id, only_updates_since_last_import = false)
      importer = Importer.find(importer_id)
      importer.current_run
      import(importer, only_updates_since_last_import)
      schedule(importer) if importer.schedulable?
    end

    def import(importer, only_updates_since_last_import)
      importer.only_updates = only_updates_since_last_import || false
      return unless importer.valid_import?
      importer.import_collections
      importer.import_works
      importer.create_parent_child_relationships unless importer.validate_only
      # NOTE(bkiahstroud): Added method to add memberships
      importer&.create_memberships unless importer.validate_only
    end

    def schedule(importer)
      ImporterJob.set(wait_until: importer.next_import_at).perform_later(importer.id, true)
    end
  end
end
