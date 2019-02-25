# frozen_string_literal: true

class SolrEndpoint < Endpoint
  store :options, accessors: %i[url collection]

  def connection
    # We remove the adapter, otherwise RSolr 2 will try to use it as a Faraday middleware
    RSolr.connect(connection_options.without('adapter'))
  end

  # @return [Hash] options for the RSolr connection.
  def connection_options
    bl_defaults = Blacklight.connection_config
    af_defaults = ActiveFedora::SolrService.instance.conn.options
    switchable_options.reverse_merge(bl_defaults).reverse_merge(af_defaults)
  end

  def ping
    connection.get('admin/ping')['status']
  rescue RSolr::Error::Http, RSolr::Error::ConnectionRefused
    false
  end

  def switch!
    ActiveFedora::SolrService.instance.conn = connection
    Blacklight.connection_config = connection_options
    Blacklight.default_index = nil
  end

  # Remove the solr collection then destroy this record
  def remove!
    # Spin off as a job, so that it can fail and be retried separately from the other logic.
    RemoveSolrCollectionJob.perform_later(collection, connection_options)
    destroy
  end

  def self.reset!
    ActiveFedora::SolrService.reset!
    Blacklight.connection_config = nil
    Blacklight.default_index = nil
  end
end
