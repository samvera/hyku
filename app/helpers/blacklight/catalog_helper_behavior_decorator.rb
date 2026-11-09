# frozen_string_literal: true

# OVERRIDE blacklight 7.42.0 to route both thumbnail APIs at Blacklight's
# ThumbnailPresenter, which Hyku decorates, and to stay off blacklight's
# deprecated render_thumbnail_tag and thumbnail_url
module Blacklight
  module CatalogHelperBehaviorDecorator
    def render_thumbnail_tag(document, image_options = {}, url_options = {})
      thumbnail_presenter_for(document).thumbnail_tag(image_options, url_options)
    end

    def thumbnail_url(document)
      thumbnail_presenter_for(document).url
    end

    private

    def thumbnail_presenter_for(document)
      document = document.try(:solr_document) || document
      document_presenter(document).thumbnail
    end
  end
end

Blacklight::CatalogHelperBehavior.prepend(Blacklight::CatalogHelperBehaviorDecorator)
