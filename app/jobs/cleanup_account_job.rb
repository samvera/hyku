class CleanupAccountJob < ActiveJob::Base
  non_tenant_job

  def perform(account)
    cleanup_solr(account)
    cleanup_fedora(account)
    cleanup_redis(account)
    cleanup_database(account)
    account.destroy
  end

  private

    def cleanup_fedora(account)
      # Return immediately if fcrepo_endpoint doesn't exist
      return unless account.fcrepo_endpoint && !account.fcrepo_endpoint.instance_of?(NilFcrepoEndpoint)
      client = fcrepo_client(account)
      # Preceding slash must be removed from base_path when calling delete()
      client.delete(account.fcrepo_endpoint.base_path.sub!(%r{^/}, ''))
      account.fcrepo_endpoint.destroy
    end

    def cleanup_redis(account)
      # Return immediately if redis_endpoint doesn't exist
      return unless account.redis_endpoint && !account.redis_endpoint.instance_of?(NilRedisEndpoint)
      redis_ns = redis_namespace(account)
      # Redis::Namespace currently doesn't support flushall or flushdb.
      # See https://github.com/resque/redis-namespace/issues/56
      # So, instead we select all keys in current namespace and delete
      keys = redis_ns.keys '*'
      return if keys.empty?
      # Delete in slices to avoid "stack level too deep" errors for large numbers of keys
      # See https://github.com/redis/redis-rb/issues/122
      keys.each_slice(1000) { |key_slice| redis_ns.del(*key_slice) }
      account.redis_endpoint.destroy
    end

    def cleanup_solr(account)
      # A partially set up account, may never have been given a solr_endpoint.
      return unless account.solr_endpoint && !account.solr_endpoint.instance_of?(NilSolrEndpoint)
      # Spin off as a job, so that it can fail and be retried separately from the other logic.
      RemoveSolrCollectionJob.perform_later(account.solr_endpoint.collection, account.solr_endpoint.connection_options)
      account.solr_endpoint.destroy
    end

    def cleanup_database(account)
      Apartment::Tenant.drop(account.tenant)
    rescue
      nil # ignore if account.tenant missing
    end

    def fcrepo_client(account)
      # Ensure we are pointed at the account's Fedora endpoint and return connection
      account.fcrepo_endpoint.switch!
      ActiveFedora.fedora.connection
    end

    def redis_namespace(account)
      # Ensure Redis is switched to account's namespace
      account.redis_endpoint.switch!
      # Return a Redis::Namespace which is already limited to account's namespace
      Hyrax::RedisEventStore.instance
    end
end
