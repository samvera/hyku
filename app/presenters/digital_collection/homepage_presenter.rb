# frozen_string_literal: true

module DigitalCollection
  class HomepagePresenter
    include ThemeHomepage

    def hero_collections
      @hero_collections ||= featured_collections.map do |featured|
        Hyrax::CollectionPresenter.new(featured.presenter.solr_document, @current_ability)
      end
    end
  end
end
