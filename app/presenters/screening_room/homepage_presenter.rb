# frozen_string_literal: true

module ScreeningRoom
  class HomepagePresenter
    include ThemeHelper

    def initialize(search_service:, featured_work_list:, current_ability:, request: nil)
      @search_service = search_service
      @featured_work_list = featured_work_list
      @current_ability = current_ability
      @request = request
    end

    def spotlight_works
      @spotlight_works ||= begin
        featured = @featured_work_list.featured_works
        readable = theme_readable_ids(featured.map { |work| work.presenter.id })

        featured.select { |work| readable.include?(work.presenter.id) }.map(&:presenter)
      end
    end

    def representative_for(work)
      representatives[work.representative_id]
    end

    private

    def representatives
      @representatives ||= authorized_documents(spotlight_works.map(&:representative_id).compact_blank.uniq)
                           .each_with_object({}) do |document, memo|
        memo[document.id] = Hyrax::FileSetPresenter.new(document, @current_ability, @request)
      end
    end

    def authorized_documents(ids)
      return [] if ids.empty?

      Hyrax::SolrQueryService.new
                             .with_field_pairs(field_pairs: { id: ids }, join_with: ' OR ')
                             .accessible_by(ability: @current_ability)
                             .solr_documents
    end
  end
end
