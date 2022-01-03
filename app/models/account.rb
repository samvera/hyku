# frozen_string_literal: true

# Customer organization account
class Account < ApplicationRecord
  include AccountEndpoints
  include AccountSettings
  include AccountCname
  attr_readonly :tenant

  has_many :sites, dependent: :destroy
  has_many :domain_names, dependent: :destroy
  has_many :full_account_cross_searches,
           class_name: 'AccountCrossSearch',
           dependent: :destroy,
           foreign_key: 'search_account_id',
           inverse_of: :search_account
  has_many :full_accounts, class_name: 'Account', through: :full_account_cross_searches
  has_many :search_account_cross_searches,
           class_name: 'AccountCrossSearch',
           dependent: :destroy,
           foreign_key: 'full_account_id',
           inverse_of: :full_account
  has_many :search_accounts, class_name: 'Account', through: :search_account_cross_searches

  accepts_nested_attributes_for :domain_names, allow_destroy: true
  accepts_nested_attributes_for :full_accounts
  accepts_nested_attributes_for :full_account_cross_searches, allow_destroy: true

  scope :is_public, -> { where(is_public: true) }
  scope :sorted_by_name, -> { order("name ASC") }
  scope :full_accounts, -> { where(search_only: false) }

  before_validation do
    self.tenant ||= SecureRandom.uuid
    self.cname ||= self.class.default_cname(name)
  end

  validates :name, presence: true, uniqueness: true
  validates :tenant, presence: true,
                     uniqueness: true,
                     format: { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/ },
                     unless: proc { |a| a.tenant == 'public' }

  def self.admin_host
    host = ENV.fetch('HYKU_ADMIN_HOST', nil)
    host ||= ENV['HOST']
    host ||= 'localhost'
    canonical_cname(host)
  end

  def self.root_host
    host = ENV.fetch('HYKU_ROOT_HOST', nil)
    host ||= ENV['HOST']
    host ||= 'localhost'
    canonical_cname(host)
  end

  def self.tenants(tenant_list)
    return Account.all if tenant_list.blank?
    joins(:domain_names).where(domain_names: { cname: tenant_list })
  end

  # @return [Account] a placeholder account using the default connections configured by the application
  def self.single_tenant_default
    @single_tenant_default ||= Account.from_cname('single.tenant.default')
    @single_tenant_default ||= Account.new do |a|
      a.build_solr_endpoint
      a.build_fcrepo_endpoint
      a.build_redis_endpoint
      a.build_data_cite_endpoint
    end
    @single_tenant_default
  end

  def self.global_tenant?
    # Global tenant only exists when multitenancy is enabled and NOT in test environment
    # (In test environment tenant switching is currently not possible)
    return false unless ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MULTITENANT', false)) && !Rails.env.test?
    Apartment::Tenant.default_tenant == Apartment::Tenant.current
  end

  # Make all the account specific connections active
  def switch!
    solr_endpoint.switch!
    fcrepo_endpoint.switch!
    redis_endpoint.switch!
    data_cite_endpoint.switch!
    switch_host!(cname)
    setup_tenant_cache(cache_api?) if self.class.column_names.include?('settings')
  end

  def switch
    switch!
    yield
  ensure
    reset!
  end

  def reset!
    setup_tenant_cache(cache_api?) if self.class.column_names.include?('settings')
    SolrEndpoint.reset!
    FcrepoEndpoint.reset!
    RedisEndpoint.reset!
    DataCiteEndpoint.reset!
    switch_host!(nil)
  end

  def switch_host!(cname)
    Rails.application.routes.default_url_options[:host] = cname
    Hyrax::Engine.routes.default_url_options[:host] = cname
  end

  def setup_tenant_cache(is_enabled)
    Rails.application.config.action_controller.perform_caching = is_enabled
    ActionController::Base.perform_caching = is_enabled
    # rubocop:disable Style/ConditionalAssignment
    if is_enabled
      Rails.application.config.cache_store = :redis_cache_store, { url: Redis.current.id }
    else
      Rails.application.config.cache_store = :file_store, ENV.fetch('HYKU_CACHE_ROOT', '/app/samvera/file_cache')
    end
    # rubocop:enable Style/ConditionalAssignment
    Rails.cache = ActiveSupport::Cache.lookup_store(Rails.application.config.cache_store)
  end

  # Get admin emails associated with this account/site
  def admin_emails
    # Must run this against proper tenant database
    Apartment::Tenant.switch(tenant) do
      Site.instance.admin_emails
    end
  end

  # Set admin emails associated with this account/site
  # @param [Array<String>] Array of user emails
  def admin_emails=(emails)
    # Must run this against proper tenant database
    Apartment::Tenant.switch(tenant) do
      Site.instance.admin_emails = emails
    end
  end

  def cache_api?
    cache_api
  end
end
