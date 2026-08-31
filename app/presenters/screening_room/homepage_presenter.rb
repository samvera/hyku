# frozen_string_literal: true

module ScreeningRoom
  class HomepagePresenter
    include ThemeHomepage

    def spotlight_works
      @spotlight_works ||= featured_works.map(&:presenter)
    end

    def representative_for(work)
      representatives[work.representative_id]
    end

    private

    def representatives
      @representatives ||= authorized_documents(spotlight_works.map(&:representative_id).compact_blank.uniq)
                           .each_with_object({}) do |document, memo|
        memo[document.id] = Hyrax::FileSetPresenter.new(document, @current_ability)
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
