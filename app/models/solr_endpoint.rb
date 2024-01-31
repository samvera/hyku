# frozen_string_literal: true

class SolrEndpoint < Endpoint
  # @see https://github.com/samvera/hyku/wiki/Updating-Hyku-6-with-Hyrax-5-Developer-Notes#indexing-considerations
  SOLR_SERVICE = ::ActiveFedora::SolrService # DO NOT CHANGE For Hyrax 5 implementations

  ##
  # This module exposes {#switch!}, a method common to both {NilSolrEndpoint} and {SolrEndpoint}.
  #
  # In the case of the {NilSolrEndpoint} the configuration options are invalid; yet we still want to
  # perform the switch!  The act of switching end points does not raise an error, but later
  # accessing that end-point will raise an error.
  module SwitchMethod
    def switch!
      # This must remain Hyrax::SolrService; as Hyrax::SolrService
      SOLR_SERVICE.instance.conn = connection
      Valkyrie::IndexingAdapter.adapters[:solr_index].connection = connection
      Blacklight.connection_config = connection_options
      Blacklight.default_index = nil
    end
  end
  include SwitchMethod

  has_one :account, dependent: nil, foreign_key: :solr_endpoint_id # rubocop:disable Rails/RedundantForeignKey

  store :options, accessors: %i[url collection]

  def connection
    # We remove the adapter, otherwise RSolr 2 will try to use it as a Faraday middleware
    RSolr.connect(connection_options.without('adapter'))
  end

  # @return [Hash] options for the RSolr connection.
  def connection_options
    bl_defaults = Blacklight.connection_config
    af_defaults = SOLR_SERVICE.instance.conn.options
    switchable_options.reverse_merge(bl_defaults).reverse_merge(af_defaults)
  end

  def ping
    connection.get('admin/ping')['status']
  rescue RSolr::Error::Http, RSolr::Error::ConnectionRefused
    false
  end

  # Remove the solr collection then destroy this record
  def remove!
    # NOTE: Other end points first call switch!; is that an oversight?  Perhaps not as we're relying
    # on a scheduled job to do the destructive work.

    # Spin off as a job, so that it can fail and be retried separately from the other logic.
    if account.search_only?
      RemoveSolrCollectionJob.perform_later(collection, connection_options, 'cross_search_tenant')
    else
      RemoveSolrCollectionJob.perform_later(collection, connection_options)
    end
    destroy
  end

  def self.reset!
    SOLR_SERVICE.reset!
    Blacklight.connection_config = Blacklight.blacklight_yml[::Rails.env].symbolize_keys
    Blacklight.default_index = nil
  end
end
