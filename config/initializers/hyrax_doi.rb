# frozen_string_literal: true

# Credentials come from each tenant's DataCiteEndpoint rather than the environment, which
# is the whole of Hyku's DOI integration -- the gem registers its own registrar, listener,
# and helpers.
Rails.application.config.to_prepare do
  Hyrax::DOI.configure do |config|
    config.credential_store = Hyku::DataCiteCredentialStore.new
  end
end
