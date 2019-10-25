RSpec.configure do |config|
  # The before and after blocks must run instantaneously, because Capybara
  # might not actually be used in all examples where it's included.
  config.after do
    example = RSpec.current_example
    if example.metadata[:multitenant] || example.metadata[:singletenant]
      allow(Settings.multitenancy).to receive(:enabled).and_call_original
      Rails.application.reload_routes!
    end
  end

  # There are 3 optional flags available to a test block.  Only ONE will be active
  # at any given time.  They are (with areas of likely use):
  #   :multitenant  - general case default, only needs to be explicit for types described below
  #   :singletenant - For tests explicitly written for singletenancy, in particular routing
  #   :faketenant   - Ignoring multitenancy, but pretending *some* tenant is always active
  #
  # Spec types:
  #   :feature - Because multitenancy affects routing, all :feature tests default to :singletenant.
  #              Similarly, :feature tests cannot use :faketenant (would fail anyway).
  #   :controller - default to :faketenant, since most resource controllers can be tested
  #                 without routing as long as they get some account.

  config.before do
    example = RSpec.current_example
    if example.metadata[:multitenant]
      allow(Settings.multitenancy).to receive(:enabled).and_return(true)
      if ENV['WEB_HOST']
        Settings.multitenancy.admin_host = ENV['WEB_HOST']
        # rubocop:disable Style/FormatStringToken
        Settings.multitenancy.default_host = "%{tenant}.#{ENV['WEB_HOST']}"
        # rubocop:enable Style/FormatStringToken
      end
      Rails.application.reload_routes!
    elsif example.metadata[:singletenant] || example.metadata[:type] == :feature
      example.metadata[:singletenant] = true if example.metadata[:type] == :feature # flag for cleanup later
      allow(Settings.multitenancy).to receive(:enabled).and_return(false)
      Rails.application.reload_routes!
    elsif example.metadata[:faketenant] || example.metadata[:type] == :controller
      example.metadata[:faketenant] = true if example.metadata[:type] == :controller # flag for cleanup later
      acct = FactoryBot.build(:account, tenant: 'FakeTenant', cname: 'tenant1')
      allow(acct).to receive(:persisted?).and_return true # nevertheless
      allow(Account).to receive(:from_request).and_return(acct)
    else
      if ENV['WEB_HOST']
        Settings.multitenancy.admin_host = nil
        Settings.multitenancy.default_host = nil
      end
      Rails.application.reload_routes!
    end
  end
end
