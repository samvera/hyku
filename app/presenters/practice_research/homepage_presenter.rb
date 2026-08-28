# frozen_string_literal: true

module PracticeResearch
  class HomepagePresenter
    include ThemeHomepage

    SUBJECT_LIMIT = 16

    def work_types
      @work_types ||= model_counts.sort_by { |_model, count| -count }.to_h
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

    def model_counts
      works = ::Hyrax::ModelRegistry.work_rdf_representations

      facet_items('has_model_ssim', 'f.has_model_ssim.facet.limit' => '-1')
        .select { |item| works.include?(item.value) }
        .to_h { |item| [item.value, item.hits] }
    end
  end
end
