# frozen_string_literal: true

# Customer organization account
class Account < ApplicationRecord
  # @param [String] piece the tenant piece of the canonical name
  # @return [String] full canonical name
  # @raise [ArgumentError] if piece contains a trailing dot
  # @see Settings.multitenancy.default_host
  def self.default_cname(piece)
    return unless piece
    raise ArgumentError, "param '#{piece}' must not contain trailing dots" if piece =~ /\.\Z/
    default_host = Settings.multitenancy.default_host || "%{tenant}.#{admin_host}"
    canonical_cname(format(default_host, tenant: piece.parameterize))
  end

  # Canonicalize the account cname or request host for comparison
  # @param [String] cname distinct part of host name
  # @return [String] canonicalized host name
  def self.canonical_cname(cname)
    # DNS host names are case-insensitive. Trim trailing dot(s).
    cname &&= cname.downcase.sub(/\.*\Z/, '')
    cname
  end

  def self.admin_host
    host = Settings.multitenancy.admin_host
    host ||= ENV['HOST']
    host ||= 'localhost'
    canonical_cname(host)
  end

  def self.root_host
    host = Settings.multitenancy.root_host
    host ||= ENV['HOST']
    host ||= 'localhost'
    canonical_cname(host)
  end

  def self.tenants(tenant_list)
    return Account.all if tenant_list.blank?
    where(cname: tenant_list)
  end

  attr_readonly :tenant
  # name is unused after create, only used by sign_up/new forms
  validates :name,
            presence: true,
            unless: :cname_is_blank?

  validates :tenant, presence: true, uniqueness: true
  validates :cname, presence: true, uniqueness: true, exclusion: { in: [default_cname('')] }

  belongs_to :solr_endpoint, dependent: :delete
  belongs_to :fcrepo_endpoint, dependent: :delete
  belongs_to :redis_endpoint, dependent: :delete

  accepts_nested_attributes_for :solr_endpoint, :fcrepo_endpoint, :redis_endpoint, update_only: true

  before_validation do
    self.tenant ||= SecureRandom.uuid
    self.cname ||= self.class.default_cname(name)
  end

  before_save :canonicalize_cname

  # @return [Account]
  def self.from_request(request)
    find_by(cname: canonical_cname(request.host))
  end

  # @return [Account] a placeholder account using the default connections configured by the application
  def self.single_tenant_default
    @single_tenant_default ||= Account.find_by(cname: 'single.tenant.default')
    @single_tenant_default ||= Account.new do |a|
      a.build_solr_endpoint
      a.build_fcrepo_endpoint
      a.build_redis_endpoint
    end
    @single_tenant_default
  end

  # @return [Boolean] whether this Account is the global tenant in a multitenant environment
  def self.global_tenant?
    # Global tenant only exists when multitenancy is enabled and NOT in test environment
    # (In test environment tenant switching is currently not possible)
    return false unless Settings.multitenancy.enabled && !Rails.env.test?
    Apartment::Tenant.default_tenant == Apartment::Tenant.current
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

  # Make all the account specific connections active
  def switch!
    solr_endpoint.switch!
    fcrepo_endpoint.switch!
    redis_endpoint.switch!
  end

  def switch
    switch!
    yield
  ensure
    reset!
  end

  def reset!
    SolrEndpoint.reset!
    FcrepoEndpoint.reset!
    RedisEndpoint.reset!
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

  private

    def default_cname(piece = name)
      self.class.default_cname(piece)
    end

    def cname_is_blank?
      cname.present? && cname != default_cname("")
    end

    def canonicalize_cname
      self.cname &&= self.class.canonical_cname(cname)
    end
end
