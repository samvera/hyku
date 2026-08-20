# frozen_string_literal: true

module PracticeResearch
  class HomepagePresenter
    include ThemeHomepage

    SUBJECT_LIMIT = 16

    def work_types
      @work_types ||= model_counts.sort_by { |_model, count| -count }.to_h
    end

    def subjects
      @subjects ||= @search_service.facet_field_response(
        'subject_sim', 'facet.mincount' => '1', "f.subject_sim.facet.limit" => SUBJECT_LIMIT.to_s
      ).aggregations['subject_sim']&.items.to_a
    end

    private

    def facets
      @facets ||= @search_service.facet_field_response(
        'has_model_ssim', 'facet.mincount' => '1', 'f.has_model_ssim.facet.limit' => '-1'
      )
    end

    def model_counts
      works = ::Hyrax::ModelRegistry.work_rdf_representations

      facets.aggregations['has_model_ssim']
            .items
            .select { |item| works.include?(item.value) }
            .to_h { |item| [item.value, item.hits] }
    end
  end
end
