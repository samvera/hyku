# frozen_string_literal: true

class NilSolrEndpoint < NilEndpoint
  ##
  # @note Yes, we're switching to a nil end point with an invalidate {#connection}.  If we did not
  #       switch, to this bogus end-point then later calls to the connection/ping would hit the
  #       prior end-point.
  include SolrEndpoint::SwitchMethod

  def url
    'Solr not initialized'
  end

  # Return an RSolr connection, that points at an invalid endpoint
  # Note: We could have returned a NilRSolrConnection here, but Blacklight
  # makes it's own RSolr connection, so we'd end up with an RSolr connection in
  # blacklight anyway.
  def connection
    RSolr.connect(connection_options)
  end

  # Return options that will never return a valid connection.
  def connection_options
    { url: 'http://127.0.0.1:99999/nil_solr_endpoint' }
  end
end
