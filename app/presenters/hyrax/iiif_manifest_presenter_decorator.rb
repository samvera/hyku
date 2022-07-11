# frozen_string_literal: true

# OVERRIDE Hyrax 3.4.0 to check the site's ssl_configured when setting protocols
module Hyrax
  module IiifManifestPresenterDecorator
    def search_service
      url = Rails.application.routes.url_helpers.solr_document_url(id, host: hostname)
      Site.account.ssl_configured ? url.sub(/\Ahttp:/, 'https:') : url
    end

    ##
    # @return [String] the URL where the manifest can be found
    def manifest_url
      return '' if id.blank?

      protocol = Site.account.ssl_configured ? 'https' : 'http'
      Rails.application.routes.url_helpers.polymorphic_url([:manifest, model], host: hostname, protocol: protocol)
    end
  end
end

Hyrax::IiifManifestPresenter.prepend(Hyrax::IiifManifestPresenterDecorator)
