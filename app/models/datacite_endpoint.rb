# frozen_string_literal: true

class DataCiteEndpoint < ::Endpoint
  has_one :account, dependent: nil, foreign_key: :data_cite_endpoint_id # rubocop:disable Rails/RedundantForeignKey

  store :options, accessors: %i[mode prefix username password]

  # Nothing to switch. Hyku::DataCiteCredentialStore reads this record per registration, so
  # credentials follow the current tenant without being pushed into process-wide state --
  # which is what let concurrent workers serving different tenants overwrite each other.
  def switch!; end

  # No special handling just destroy this record
  def remove!
    destroy
  end

  def self.reset!; end

  # Confirms both that DataCite is reachable and that these credentials work. Built from this
  # record rather than the configured store, which resolves the current tenant -- on the
  # proprietor page every account would otherwise report the same tenant's status.
  def ping
    credentials = Hyrax::DOI::Credentials.new(provider: 'datacite', prefix:, username:,
                                              password:, mode:)
    return false unless credentials.complete?

    Hyrax::DOI::DataCiteRegistrar.new(credentials:).ping.success?
  rescue StandardError
    false
  end
end
