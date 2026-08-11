# frozen_string_literal: true

module Hyku
  # Reads DataCite credentials from the current tenant's DataCiteEndpoint.
  #
  # The gem resolves credentials through this on every registration rather than caching
  # them, so a background job that has switched tenants gets that tenant's account. Nothing
  # is pushed into process-wide state, which is what made the previous approach unsafe:
  # concurrent Sidekiq threads serving different tenants overwrote each other's credentials.
  class DataCiteCredentialStore < Hyrax::DOI::CredentialStore
    def fetch(provider:)
      return env_credentials(provider) if Hyku.single_tenant?

      endpoint = Site.instance&.account&.data_cite_endpoint

      Hyrax::DOI::Credentials.new(provider: provider,
                                  prefix: endpoint&.prefix,
                                  username: endpoint&.username,
                                  password: endpoint&.password,
                                  mode: endpoint&.mode)
    end

    private

    # A single-tenant install has no proprietor route to store credentials in, so they come
    # from the environment -- as Solr and Fedora do in that mode.
    #
    # Multitenant deliberately does not fall back here. A consortial install has one tenant
    # per institution, and inheriting an instance-wide account would mint a tenant's DOIs
    # under someone else's prefix. A blank fieldset there means this tenant does not mint.
    def env_credentials(provider)
      Hyrax::DOI::Credentials.new(provider: provider,
                                  prefix: ENV.fetch('DATACITE_PREFIX', nil),
                                  username: ENV.fetch('DATACITE_USERNAME', nil),
                                  password: ENV.fetch('DATACITE_PASSWORD', nil),
                                  mode: ENV.fetch('DATACITE_MODE', 'test'))
    end
  end
end
