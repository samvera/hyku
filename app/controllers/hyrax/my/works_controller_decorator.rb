# frozen_string_literal: true

# OVERRIDE Hyrax 5.2.0 to add custom sort fields and a Work Type facet while
# in the dashboard for works

module Hyrax
  module My
    module WorksControllerDecorator
      def configure_facets
        configure_blacklight do |config|
          # clear facets copied from the CatalogController
          config.sort_fields.clear
          config.add_sort_field "date_uploaded_dtsi desc", label: "date uploaded \u25BC"
          config.add_sort_field "date_uploaded_dtsi asc", label: "date uploaded \u25B2"
          config.add_sort_field "date_modified_dtsi desc", label: "date modified \u25BC"
          config.add_sort_field "date_modified_dtsi asc", label: "date modified \u25B2"
          config.add_sort_field "system_create_dtsi desc", label: "date created \u25BC"
          config.add_sort_field "system_create_dtsi asc", label: "date created \u25B2"
          config.add_sort_field "depositor_ssi asc, title_ssi asc", label: "depositor (A-Z)"
          config.add_sort_field "depositor_ssi desc, title_ssi desc", label: "depositor (Z-A)"
          config.add_sort_field "creator_ssi asc, title_ssi asc", label: "creator (A-Z)"
          config.add_sort_field "creator_ssi desc, title_ssi desc", label: "creator (Z-A)"

          # A "Work Type" dropdown in the dashboard filter row (the row renders
          # every configured facet). Guarded in case this config already copied
          # the facet from the CatalogController.
          unless config.facet_fields.key?('has_model_ssim')
            config.add_facet_field 'has_model_ssim', label: "Work Type",
                                                     helper_method: :work_type_facet_label, limit: 10
          end
        end
      end
    end
  end
end

Hyrax::My::WorksController.singleton_class.send(:prepend, Hyrax::My::WorksControllerDecorator)
Hyrax::My::WorksController.configure_facets
