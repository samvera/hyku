# frozen_string_literal: true

# OVERRIDE Hyrax 3.4.0 to use site in the search_service method
module Hyrax
  module IiifManifestPresenterDecorator
    def search_service
      url = Rails.application.routes.url_helpers.solr_document_url(id, host: hostname)
      Site.account.ssl_configured ? url.sub(/\Ahttp:/, 'https:') : url
    end
  end
end

Hyrax::IiifManifestPresenter.prepend(Hyrax::IiifManifestPresenterDecorator)
