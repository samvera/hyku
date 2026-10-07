# frozen_string_literal: true

# Helpers for the digital collection theme's collection, work and file set pages.
module DigitalCollectionShowHelper
  def dc_breadcrumb_trail(presenter)
    home = [t('hyrax.controls.home'), hyrax.root_path]
    case presenter
    when Hyrax::CollectionPresenter
      [home, [presenter.to_s, nil], dc_back_to_search_crumb].compact
    when Hyrax::FileSetPresenter
      work = presenter.parent
      [home, dc_collection_crumb(work), ([work.to_s, main_app.polymorphic_path(work)] if work)].compact
    else
      [home, dc_collection_crumb(presenter), [presenter.to_s, nil], dc_back_to_search_crumb].compact
    end
  end

  private

  def dc_collection_crumb(work)
    collection = work.try(:member_of_collection_presenters)&.find { |parent| parent.is_a?(Hyrax::CollectionPresenter) }
    [collection.to_s, hyrax.collection_path(collection.id)] if collection
  end

  def dc_back_to_search_crumb
    referer = URI.parse(request.referer.to_s)
    return unless referer.host == request.host && referer.path.start_with?(URI.parse(main_app.search_catalog_path).path)

    [t('hyrax.bread_crumb.search_results'), request.referer]
  rescue URI::InvalidURIError
    nil
  end
end
