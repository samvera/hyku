# frozen_string_literal: true

class FcrepoEndpoint < Endpoint
  has_one :account, dependent: nil, foreign_key: :fcrepo_endpoint_id # rubocop:disable Rails/RedundantForeignKey

  store :options, accessors: %i[url base_path]

  def url
    options&.[](:url) || ActiveFedora.config&.credentials&.[](:url)
  end

  def switch!
    ActiveFedora::Fedora.register(switchable_options.symbolize_keys)
  end

  def self.reset!
    ActiveFedora::Fedora.reset!
  end

  def ping
    ActiveFedora::Fedora.instance.connection.head(
      ActiveFedora::Fedora.instance.connection.connection.http.url_prefix.to_s
    ).response.success?
  rescue StandardError
    false
  end

  # Remove the Fedora resource for this endpoint, then destroy the record
  def remove!
    switch!
    # Preceding slash must be removed from base_path when calling delete()
    path = base_path.sub(%r{^/}, '')
    ActiveFedora.fedora.connection.delete(path)
    destroy
  end
end
