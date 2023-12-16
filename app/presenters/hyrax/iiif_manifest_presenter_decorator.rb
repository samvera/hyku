# frozen_string_literal: true

# OVERRIDE Hyrax 3.4.0 to check the site's ssl_configured when setting protocols
module Hyrax
  module IiifManifestPresenterDecorator
    attr_writer :iiif_version
    ##
    # @note The #search_service method is to help configure the IIIF Manifest gem
    # @note As of 3.4.2, the Hyrax::IiifManifestPresenter does not implement the
    #    #search_service.
    # @todo Write test when we incorporate the IIIF Print gem
    def search_service
      # When Hyku introduces the IIIF Print gem, we will then have a "super" method
      # which creates a URL based on the IIIF Print gem's implementation.
      # However, the IIIF Print gem has no knowledge of Site.account and so we need
      # to massage the URL to be SSL or non-SSL.
      #
      # The fallback URL is the previous implementation.
      url = if defined?(super)
              super
            else
              Rails.application.routes.url_helpers.solr_document_url(id, host: hostname)
            end
      Site.account.ssl_configured ? url.sub(/\Ahttp:/, 'https:') : url
    end

    ##
    # @return [String] the URL where the manifest can be found
    def manifest_url
      return '' if id.blank?

      protocol = Site.account.ssl_configured ? 'https' : 'http'
      Rails.application.routes.url_helpers.polymorphic_url([:manifest, model], host: hostname, protocol:)
    end

    def iiif_version
      @iiif_version || 3
    end

    module DisplayImagePresenterDecorator
      include Hyrax::IiifAv::DisplaysContent

      # override Hyrax to keep pdfs from gumming up the v3 manifest
      # in app/presenters/hyrax/iiif_manifest_presenter.rb
      def file_set?
        super && (image? || audio? || video?)
      end
    end
  end
end

Hyrax::IiifManifestPresenter.prepend(Hyrax::IiifManifestPresenterDecorator)
Hyrax::IiifManifestPresenter::DisplayImagePresenter
  .prepend(Hyrax::IiifManifestPresenterDecorator::DisplayImagePresenterDecorator)
