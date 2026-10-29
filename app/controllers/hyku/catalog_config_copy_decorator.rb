# frozen_string_literal: true

module Hyku
  # OVERRIDE Hyrax v5.3.0 for the controllers that copy the catalog's config at boot:
  #   - each request's blacklight_config takes the catalog's facet, index and search
  #     fields, which the metadata profile builds per request, keeping the controller's
  #     other settings; controlled properties therefore facet and search by label, as
  #     in the catalog (docs/controlled-vocabularies.md)
  #   - answer the catalog predicates those fields name in `if:`, render_optionally?
  #     and render_in_tenant?
  #   - link those fields' values to catalog searches; Blacklight's default resolves
  #     against the engine routes
  module CatalogConfigCopyDecorator
    PROFILE_DRIVEN_FIELDS = %i[facet_fields index_fields search_fields].freeze

    def blacklight_config
      @blacklight_config ||= super.deep_copy.tap do |config|
        catalog = ::CatalogController.new.blacklight_config
        PROFILE_DRIVEN_FIELDS.each { |fields| config.public_send("#{fields}=", catalog.public_send(fields).deep_dup) }
      end
    end

    private

    delegate :render_optionally?, :render_in_tenant?, to: :catalog_field_conditions, private: true

    def catalog_field_conditions
      @catalog_field_conditions ||= ::CatalogController.allocate
    end

    def search_action_url(options = {})
      main_app.search_catalog_url(options.except(:controller, :action))
    end
  end
end

[Hyrax::WorksControllerBehavior, Hyrax::CollectionsController, Hyrax::FileSetsController,
 Hyrax::SingleUseLinksViewerController].each { |copier| copier.prepend(Hyku::CatalogConfigCopyDecorator) }
