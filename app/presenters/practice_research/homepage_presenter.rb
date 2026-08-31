# frozen_string_literal: true

module PracticeResearch
  class HomepagePresenter
    include ThemeHomepage

    SUBJECT_LIMIT = 16
    TYPE_LIMIT = 4

    # Work type is a model facet, and a tenant that hides it from the catalog
    # still has resource type to browse by, so the band names whichever axis it
    # could read.
    def browse_types
      @browse_types ||= begin
        models = model_counts
        if models.any?
          { field: 'has_model_ssim', items: models }
        else
          { field: 'resource_type_sim', items: resource_type_counts }
        end
      end
    end

    def subjects
      @subjects ||= facet_items('subject_sim', "f.subject_sim.facet.limit" => SUBJECT_LIMIT.to_s)
    end

    private

    # A tenant can remove any facet from the catalog config, and Blacklight
    # raises rather than returning nothing when asked to facet on a field it
    # does not know, so a theme cannot assume a facet exists.
    def facet_items(field, extra_params = {})
      return [] unless @search_service.blacklight_config.facet_fields.key?(field)

      @search_service.facet_field_response(field, { 'facet.mincount' => '1' }.merge(extra_params))
                     .aggregations[field]&.items.to_a
    end

    # The band holds four tiles on either axis. Solr sorts by index when the
    # limit is -1, so the largest are picked here rather than in the query.
    def model_counts
      works = ::Hyrax::ModelRegistry.work_rdf_representations

      facet_items('has_model_ssim', 'f.has_model_ssim.facet.limit' => '-1')
        .select { |item| works.include?(item.value) }
        .sort_by { |item| -item.hits }
        .first(TYPE_LIMIT)
        .to_h { |item| [item.value, item.hits] }
    end

    # Solr caps this one, so a repository with a long resource type list costs
    # the same query as a short one.
    def resource_type_counts
      facet_items('resource_type_sim', 'f.resource_type_sim.facet.limit' => TYPE_LIMIT.to_s)
        .to_h { |item| [item.value, item.hits] }
    end
  end
end
