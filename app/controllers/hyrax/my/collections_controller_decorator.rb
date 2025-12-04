# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 add date, depositor, and creator sorting
module Hyrax
  module My
    module CollectionsControllerDecorator
      def configure_facets
        configure_blacklight do |config|
          # clear facets copied from the CatalogController
          config.sort_fields.clear
          # Collections don't seem to have a date_uploaded_dtsi nor date_modified_dtsi
          # we can at least use the system_modified_dtsi instead of date_modified_dtsi
          # but we will omit date_uploaded_dtsi
          config.add_sort_field "system_modified_dtsi desc", label: "date modified \u25BC"
          config.add_sort_field "system_modified_dtsi asc", label: "date modified \u25B2"
          config.add_sort_field "system_create_dtsi desc", label: "date created \u25BC"
          config.add_sort_field "system_create_dtsi asc", label: "date created \u25B2"
          config.add_sort_field "depositor_ssi asc, title_ssi asc", label: "depositor (A-Z)"
          config.add_sort_field "depositor_ssi desc, title_ssi desc", label: "depositor (Z-A)"
          config.add_sort_field "creator_ssi asc, title_ssi asc", label: "creator (A-Z)"
          config.add_sort_field "creator_ssi desc, title_ssi desc", label: "creator (Z-A)"
        end
      end
    end
  end
end

Hyrax::My::CollectionsController.singleton_class.send(:prepend, Hyrax::My::CollectionsControllerDecorator)
Hyrax::My::CollectionsController.configure_facets
