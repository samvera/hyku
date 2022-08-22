# frozen_string_literal: true

RSpec.configure do |config|
  # The around blocks must run instantaneously, because Capybara
  # might not actually be used in all examples where it's included.

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

  config.before do |example|
    if !example.metadata[:multitenant] && !example.metadata[:singletenant] && (example.metadata[:faketenant] || example.metadata[:type] == :controller)
      example.metadata[:faketenant] = true if example.metadata[:type] == :controller # flag for cleanup later
      acct = FactoryBot.build(:account, tenant: 'FakeTenant', cname: 'tenant1')
      allow(acct).to receive(:persisted?).and_return true # nevertheless
      allow(Account).to receive(:from_request).and_return(acct)
    end
  end

  config.around do |example|
    @multitenat = ENV.fetch('HYKU_MULTITENANT', nil)
    @admin_host = ENV.fetch('HYKU_ADMIN_HOST', nil)
    @default_host = ENV.fetch('HYKU_DEFAULT_HOST', nil)

    if example.metadata[:multitenant]
      ENV['HYKU_MULTITENANT'] = "true"
      if ENV['WEB_HOST']
        ENV['HYKU_ADMIN_HOST'] = ENV['WEB_HOST']
        # rubocop:disable Style/FormatStringToken
        ENV['HYKU_DEFAULT_HOST'] = "%{tenant}.#{ENV['WEB_HOST']}"
        # rubocop:enable Style/FormatStringToken
      end
      Rails.application.reload_routes!
    elsif example.metadata[:singletenant] || example.metadata[:type] == :feature
      example.metadata[:singletenant] = true if example.metadata[:type] == :feature # flag for cleanup later
      ENV['HYKU_MULTITENANT'] = "false"
      Rails.application.reload_routes!
    end

    example.run

    if example.metadata[:multitenant] || example.metadata[:singletenant]
      ENV['HYKU_MULTITENANT'] = @multitenat
      ENV['HYKU_ADMIN_HOST'] = @admin_host
      ENV['HYKU_DEFAULT_HOST'] = @default_host
      Rails.application.reload_routes!
    end
  end
end
