# frozen_string_literal: true

# Initialize and configure external dependencies for an Account
class CreateAccount
  attr_reader :account

  ##
  # @param [Account]
  def initialize(account)
    @account = account
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
    create_account_inline && create_tenant
  end

  ##
  # Create the apartment database tenant and initialize it with seed data
  def create_tenant
    Apartment::Tenant.create(account.tenant) do
      initialize_account_data
      account.switch do
        AdminSet.find_or_create_default_admin_set_id
      end
    end
  end

  # Sacrifing idempotency of our account creation jobs here to reflect
  # the dependency that exists between creating endpoints,
  # specifically Solr and Fedora, and creation of the default Admin Set.
  def create_account_inline
    CreateAccountInlineJob.perform_now(account)
  end

  private

    def initialize_account_data
      Site.update(account: account)
    end
end
