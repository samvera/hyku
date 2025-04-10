# frozen_string_literal: true

# Initialize and configure external dependencies for an Account
class CreateAccount
  attr_reader :account, :users

  ##
  # @param [Account]
  def initialize(account, users = [])
    @account = account
    @users = users
  end

  # @return [Boolean] true if save and jobs spawning were successful
  def save
    account.save && create_external_resources ? true : false
  end

  # `Apartment::Tenant.create` calls the DB adapter's `switch`, which we have a hook into
  # via an initializer.  In our hook we do `account.switch!` and that requires a well-formed
  # Account (i.e. creation steps complete, endpoints populated).  THEREFORE, `create_tenant`
  # must be called *after* all external resources are provisioned.
  def create_external_resources
    create_account_inline && account.save && create_tenant
  end

  ##
  # Create the apartment database tenant and initialize it with seed data
  def create_tenant
    Apartment::Tenant.create(account.tenant) do
      initialize_account_data
      account.switch do
        create_defaults
        fillin_translations
        add_initial_users
        schedule_recurring_jobs
        true
      end
    end
  end

  def create_defaults
    RolesService.create_default_roles!
    RolesService.create_default_hyrax_groups_with_roles!
    Hyrax::CollectionType.find_or_create_default_collection_type
    Hyrax::CollectionType.find_or_create_admin_set_type
    return if account.search_only?

    Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
  end

  # Workaround for upstream issue https://github.com/samvera/hyrax/issues/3136
  def fillin_translations
    collection_types = Hyrax::CollectionType.all
    collection_types.each do |c|
      next unless /^translation missing/.match?(c.title)
      oldtitle = c.title
      c.title = I18n.t(c.title.gsub("translation missing: en.", ''))
      c.save
      Rails.logger.debug { "#{oldtitle} changed to #{c.title}" }
    end
  end

  def add_initial_users
    users.each do |user|
      user.add_role :admin, Site.instance
      user.add_default_group_membership!
      Hyrax::Group.find_or_create_by!(name: Ability.admin_group_name).add_members_by_id(user.id)
    end
  end

  # Sacrifing idempotency of our account creation jobs here to reflect
  # the dependency that exists between creating endpoints,
  # specifically Solr and Fedora, and creation of the default Admin Set.
  def create_account_inline
    CreateAccountInlineJob.perform_now(account)
  end

  ##
  # Schedules jobs that will run automatically after
  # the first time they are called
  def schedule_recurring_jobs
    return if account.search_only?
    account.find_or_schedule_jobs
  end

  private

  def initialize_account_data
    Site.update(account:)
  end
end
