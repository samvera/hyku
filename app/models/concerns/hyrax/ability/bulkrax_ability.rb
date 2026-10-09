# frozen_string_literal: true

# A module to define who may use Bulkrax importers and exporters.
#
# Anyone who can deposit may import and export, and manages only the importers
# and exporters they own. Admins manage every importer and exporter.
module Hyrax
  module Ability
    module BulkraxAbility
      include ::Bulkrax::Ability

      def can_import_works?
        can_create_any_work?
      end

      def can_export_works?
        can_create_any_work?
      end

      def can_admin_importers?
        admin?
      end

      def can_admin_exporters?
        admin?
      end
    end
  end
end
