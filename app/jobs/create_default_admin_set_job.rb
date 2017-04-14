class CreateDefaultAdminSetJob < ActiveJob::Base
  def perform(account)
    AccountElevator.switch!(account.tenant)
    AdminSet.find_or_create_default_admin_set_id
  end
end
