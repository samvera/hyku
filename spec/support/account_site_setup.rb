RSpec.configure do |config|
  config.before do
    account = FactoryGirl.create(:sign_up_account)
    Site.update(account: account)
  end
end
