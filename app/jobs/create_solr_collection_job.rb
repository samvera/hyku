# frozen_string_literal: true

# Create a new account-specific Solr collection using the base templates
class CreateSolrCollectionJob < ApplicationJob
  non_tenant_job

  attr_accessor :account
  ##
  # @param [Account]
  def perform(account)
    @account = account
    name = account.tenant.parameterize

    if account.search_only?
      perform_for_cross_search_tenant(account, name)
    else
      perform_for_normal_tenant(account, name)
    end
  end

  def without_account(name, tenant_list = '')
    return if collection_exists?(name)
    if tenant_list.present?
      client.get '/solr/admin/collections', params: collection_options.merge(action: 'CREATEALIAS',
                                                                             name: name, collections: tenant_list)
    else
      client.get '/solr/admin/collections', params: collection_options.merge(action: 'CREATE',
                                                                             name: name)
    end
  end

  # Transform settings from nested, snaked-cased options to flattened, camel-cased options
  class CollectionOptions
    attr_reader :settings

    def initialize(settings = {})
      @settings = settings
    end

    ##
    # @example Camel-casing
    #   { replication_factor: 5 } # => { "replicationFactor" => 5 }
    # @example Blank-rejecting
    #   { emptyValue: '' } #=> { }
    # @example Nested value-flattening
    #   { collection: { config_name: 'x' } } # => { 'collection.configName' => 'x' }
    def to_h
      Hash[*settings.map { |k, v| transform_entry(k, v) }.flatten].reject { |_k, v| v.blank? }.symbolize_keys
    end

    private

      def transform_entry(k, v)
        case v
        when Hash
          v.map do |k1, v1|
            ["#{transform_key(k)}.#{transform_key(k1)}", v1]
          end
        else
          [transform_key(k), v]
        end
      end

      def transform_key(k)
        k.to_s.camelize(:lower)
      end
  end

  private

    def client
      Blacklight.default_index.connection
    end

    def collection_options
      CollectionOptions.new(account ? account.solr_collection_options : Account.solr_collection_options).to_h
    end

    def collection_exists?(name)
      response = client.get '/solr/admin/collections', params: { action: 'LIST' }
      collections = response['collections']

      collections.include? name
    end

    def collection_url(name)
      uri = URI(solr_url) + name

      uri.to_s
    end

    def solr_url
      @solr_url ||= ENV['SOLR_URL'] || solr_url_parts
      @solr_url = @solr_url.ends_with?('/') ? @solr_url : "#{@solr_url}/"
    end

    def solr_url_parts
      "http://#{ENV.fetch('SOLR_ADMIN_USER', 'admin')}:#{ENV.fetch('SOLR_ADMIN_PASSWORD', 'admin')}" \
        "@#{ENV.fetch('SOLR_HOST', 'solr')}:#{ENV.fetch('SOLR_PORT', '8983')}/solr/"
    end

    def add_solr_endpoint_to_account(account, name)
      account.create_solr_endpoint(url: collection_url(name), collection: name)
    end

    def perform_for_normal_tenant(account, name)
      unless collection_exists? name
        client.get '/solr/admin/collections', params: collection_options.merge(action: 'CREATE',
                                                                               name: name)
      end
      add_solr_endpoint_to_account(account, name)
    end

    def perform_for_cross_search_tenant(account, name)
      return if account.full_accounts.blank?
      if account.saved_changes&.[]('created_at').present? || account.solr_endpoint.is_a?(NilSolrEndpoint)
        create_shared_search_collection(account.full_accounts.map(&:tenant).uniq, name)
        account.create_solr_endpoint(url: collection_url(name), collection: name)
        account.save
      else
        solr_options = account.solr_endpoint.connection_options.dup
        RemoveSolrCollectionJob.perform_now(name, solr_options, 'cross_search_tenant')
        create_shared_search_collection(account.full_accounts.map(&:tenant).uniq, name)
        account.solr_endpoint.update(url: collection_url(name), collection: name)
      end
    end

    def create_shared_search_collection(tenant_list, name)
      return true if collection_exists?(name)
      client.get '/solr/admin/collections', params: collection_options.merge(action: 'CREATEALIAS',
                                                                             name: name, collections: tenant_list)
    end
end
