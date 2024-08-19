# frozen_string_literal: true

module AccountEndpoints
  extend ActiveSupport::Concern

  included do
    belongs_to :data_cite_endpoint, dependent: :delete
    belongs_to :fcrepo_endpoint, dependent: :delete
    belongs_to :redis_endpoint, dependent: :delete
    belongs_to :solr_endpoint, dependent: :delete
    accepts_nested_attributes_for :data_cite_endpoint,
                                  :solr_endpoint,
                                  :fcrepo_endpoint,
                                  :redis_endpoint,
                                  update_only: true
  end

  def solr_endpoint
    super || NilSolrEndpoint.new
  end

  def fcrepo_endpoint
    super || NilFcrepoEndpoint.new
  end

  def redis_endpoint
    super || NilRedisEndpoint.new
  end

  def data_cite_endpoint
    super || NilDataCiteEndpoint.new
  end
end
