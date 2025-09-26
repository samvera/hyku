# frozen_string_literal: true

ENV['APARTMENT_DISABLE_INIT'] = 'true' if ENV['DB_ADAPTER'] == 'nulldb'

unless ActiveModel::Type::Boolean.new.cast(ENV.fetch('APARTMENT_DISABLE_INIT', 'false'))
  # You can have Apartment route to the appropriate Tenant by adding some Rack middleware.
  # Apartment can support many different "Elevators" that can take care of this routing to your data.
  # Require whichever Elevator you're using below or none if you have a custom one.
  require Rails.root.join('lib', 'apartment', 'custom_console')
  require 'apartment/elevators/generic'
  # Override the console helpers
  def tenant_list
    tenant_list = Account.pluck(:name)
    tenant_list.uniq
  end

  def st(schema_name = nil)
    switch!(schema_name)
  end

  def reset!
    Account.new.reset!
    Apartment::Tenant.switch!(nil)
  end

  def tenant_info_msg
    # rubocop:disable Rails/Output
    puts "Available Tenants: #{tenant_list}\n"
    puts "Use `switch! 'tenant'` to switch tenants & `tenant_list` to see list\n"
    # rubocop:enable Rails/Output
  end
  #
  # Apartment Configuration
  #
  Apartment.configure do |config|
    # Add any models that you do not want to be multi-tenanted, but remain in the global (public) namespace.
    # A typical example would be a Customer or Tenant model that stores each Tenant's information.
    config.excluded_models = %w[Account AccountCrossSearch DomainName Endpoint User UserStat SolrEndpoint FcrepoEndpoint RedisEndpoint]
    config.excluded_models += %w[GoodJob::Execution GoodJob::Job GoodJob::Process] if ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', 'sidekiq') == 'good_job'

    # In order to migrate all of your Tenants you need to provide a list of Tenant names to Apartment.
    # You can make this dynamic by providing a Proc object to be called on migrations.
    # This object should yield an array of strings representing each Tenant name.
    config.tenant_names = -> { Account.pluck :tenant }

    #
    # ==> PostgreSQL only options

    # Specifies whether to use PostgreSQL schemas or create a new database per Tenant.
    # The default behaviour is true.
    #
    # config.use_schemas = true

    # Apartment can be forced to use raw SQL dumps instead of schema.rb for creating new schemas.
    # Use this when you are using some extra features in PostgreSQL that can't be respresented in
    # schema.rb, like materialized views etc. (only applies with use_schemas set to true).
    # (Note: this option doesn't use db/structure.sql, it creates SQL dump by executing pg_dump)
    #
    # config.use_sql = false

    # There are cases where you might want some schemas to always be in your search_path
    # e.g when using a PostgreSQL extension like hstore.
    # Any schemas added here will be available along with your selected Tenant.
    #
    # config.persistent_schemas = %w{ hstore }
    config.persistent_schemas = ['shared_extensions']

    # <== PostgreSQL only options
    #
  end

  Rails.application.config.after_initialize do
    # Callbacks from ActiveSupport::Callback: receives ZERO information about object/event.
    # Instead receives an [Apartment::Adapters::PostgresqlSchemaAdapter]
    # Therefore cannot be used as effectively as ActiveRecord hooks.
    Apartment::Tenant.adapter.class.set_callback :switch, :after, lambda {
      account = Account.find_by(tenant: current)
      account&.switch!
    }
  end
  require Rails.root.join('lib', 'middleware', 'account_elevator')
  Rails.application.config.middleware.insert_before Warden::Manager, AccountElevator
end
