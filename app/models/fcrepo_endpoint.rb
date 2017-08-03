class FcrepoEndpoint < Endpoint
  store :options, accessors: [:url, :base_path]

  def switch!
    ActiveFedora::Fedora.register(options.symbolize_keys)
  end

  def self.reset!
    ActiveFedora::Fedora.reset!
  end

  def ping
    ActiveFedora::Fedora.instance.connection.head('/').response.success?
  rescue
    false
  end

  # Remove the Fedora resource for this endpoint, then destroy the record
  def remove!
    switch!
    # Preceding slash must be removed from base_path when calling delete()
    path = base_path.sub!(%r{^/}, '')
    ActiveFedora.fedora.connection.delete(path)
    destroy
  end
end
