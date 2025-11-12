# frozen_string_literal: true

# Customer organization account
# rubocop:disable Metrics/ClassLength
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

  belongs_to :solr_endpoint, dependent: :delete
  belongs_to :fcrepo_endpoint, dependent: :delete
  belongs_to :redis_endpoint, dependent: :delete

  accepts_nested_attributes_for :solr_endpoint, :fcrepo_endpoint, :redis_endpoint, update_only: true
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
                     unless: proc { |a| a.tenant == 'public' || a.tenant == 'single' }

  # NEW: Validate that search-only accounts have at least one full account selected
  validate :search_only_must_have_full_accounts, if: :search_only?

  after_save :schedule_jobs_if_settings_changed

  def self.admin_host
    host = ENV.fetch('HYKU_ADMIN_HOST', nil)
    host ||= ENV['HOST']
    host ||= 'localhost'
    canonical_cname(host)
  end

  # @return [Account]
  def self.from_request(request)
    from_cname(request.host)
  end

  def self.from_cname(cname)
    joins(:domain_names).find_by(domain_names: { is_active: true, cname: canonical_cname(cname) })
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

  DEFAULT_FILE_CACHE_STORE = ENV.fetch('HYKU_CACHE_ROOT', '/app/samvera/file_cache')

  def setup_tenant_cache(is_enabled)
    Rails.application.config.action_controller.perform_caching = is_enabled
    ActionController::Base.perform_caching = is_enabled
    # rubocop:disable Style/ConditionalAssignment
    if is_enabled
      Rails.application.config.cache_store = :redis_cache_store, { redis: Hyrax::RedisEventStore.instance }
    else
      Rails.application.config.cache_store = :file_store, DEFAULT_FILE_CACHE_STORE
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

  def institution_name
    sites.first&.institution_name || cname
  end

  def institution_id_data
    {}
  end

  def find_job(klass)
    ActiveJob::Base.find_job(klass: klass, tenant_id: self.tenant)
  end

  def find_or_schedule_jobs
    account = Site.account
    AccountElevator.switch!(self)

    jobs_to_schedule = [
      EmbargoAutoExpiryJob,
      LeaseAutoExpiryJob
    ]

    jobs_to_schedule << BatchEmailNotificationJob if batch_email_notifications

    if ActiveModel::Type::Boolean.new.cast(ENV.fetch("HYKU_USE_QUEUED_INDEX", false))
      jobs_to_schedule << Hyrax::QueuedIndexingJob
      jobs_to_schedule << Hyrax::QueuedDeleteJob
    end

    if analytics && Hyrax.config.analytics_reporting?
      jobs_to_schedule << DepositorEmailNotificationJob if depositor_email_notifications
      jobs_to_schedule << UserStatCollectionJob
    end

    jobs_to_schedule.each do |klass|
      klass.perform_later unless find_job(klass)
    end

    account ? AccountElevator.switch!(account) : reset!
  end

  private

  def schedule_jobs_if_settings_changed
    return unless settings

    relevant_settings = [
      'batch_email_notifications',
      'depositor_email_notifications',
      'analytics'
    ]

    return unless saved_changes['settings']
    old_settings = saved_changes['settings'][0] || {}
    new_settings = saved_changes['settings'][1] || {}

    old_relevant_settings = old_settings.slice(*relevant_settings)
    new_relevant_settings = new_settings.slice(*relevant_settings)

    return unless old_relevant_settings != new_relevant_settings
    Apartment::Tenant.switch(self.tenant) do
      find_or_schedule_jobs
    end
  end

  def search_only_must_have_full_accounts
    return unless full_account_cross_searches.reject(&:marked_for_destruction?).empty?
    errors.add(:base, 'Search-only accounts must have at least one full account selected for cross-tenant search')
  end
end
# rubocop:enable Metrics/ClassLength
