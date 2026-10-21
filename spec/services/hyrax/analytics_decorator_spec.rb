# frozen_string_literal: true

RSpec.describe Hyrax::AnalyticsDecorator do
  let(:account_a) { FactoryBot.build(:sign_up_account) }
  let(:account_b) { FactoryBot.build(:sign_up_account) }
  let(:account_c) { FactoryBot.build(:sign_up_account) }
  let(:global_id) { 'G-GLOBAL0000' }

  around do |example|
    keys = %w[HYRAX_ANALYTICS_PROVIDER GOOGLE_ANALYTICS_ID GOOGLE_ANALYTICS_PROPERTY_ID GOOGLE_ACCOUNT_JSON GOOGLE_ACCOUNT_JSON_PATH]
    original = ENV.to_h.slice(*keys)
    ENV['HYRAX_ANALYTICS_PROVIDER'] = 'ga4'
    ENV['GOOGLE_ANALYTICS_ID'] = global_id
    ENV['GOOGLE_ANALYTICS_PROPERTY_ID'] = ''
    ENV['GOOGLE_ACCOUNT_JSON'] = '{}'
    ENV['GOOGLE_ACCOUNT_JSON_PATH'] = ''
    example.run
  ensure
    keys.each { |key| original.key?(key) ? ENV[key] = original[key] : ENV.delete(key) }
  end

  before do
    account_a.settings['google_analytics_id'] = 'G-TENANTAAAA'
    account_a.settings['google_analytics_property_id'] = '111111111'
    account_b.settings['google_analytics_id'] = 'G-TENANTBBBB'
    account_b.settings['google_analytics_property_id'] = '222222222'

    [account_a, account_b, account_c].each { |account| CreateAccount.new(account, []).save }
    FactoryBot.create(:domain_name, account: account_a, cname: 'tenant-a.example')
    FactoryBot.create(:domain_name, account: account_b, cname: 'tenant-b.example')
    FactoryBot.create(:domain_name, account: account_c, cname: 'tenant-c.example')
  end

  after do
    Apartment::Tenant.switch!(Apartment.default_tenant)
    RequestStore.clear!
  end

  def rendered_ids(host)
    ApplicationController.renderer.new(http_host: host)
                         .render(partial: 'shared/ga4')
                         .scan(/gtag\('config', '([^']*)'\)/).flatten
  end

  # A thread's DB connection can't see rows inside the main thread's open transaction.
  it 'keeps each tenant on its own IDs across concurrent threads', truncation: true do
    seen = Queue.new

    [[account_a, 'tenant-a.example', 'G-TENANTAAAA', '111111111', ['G-TENANTAAAA', global_id]],
     [account_b, 'tenant-b.example', 'G-TENANTBBBB', '222222222', ['G-TENANTBBBB', global_id]],
     [account_c, 'tenant-c.example', nil, nil, [global_id]]].map do |account, host, analytics_id, property_id, tag_ids|
      Thread.new do
        results = Array.new(50) do
          Apartment::Tenant.switch!(account.tenant)
          config = Hyrax::Analytics.config
          [analytics_id && config.analytics_id, property_id && config.property_id, rendered_ids(host)]
        end
        seen << [[analytics_id, property_id, tag_ids], results.uniq]
      ensure
        Apartment::Tenant.switch!(Apartment.default_tenant)
      end
    end.each(&:join)

    3.times do
      expected, actual = seen.pop
      expect(actual).to eq([expected])
    end
  end

  it "falls back to the app wide IDs for a tenant without its own" do
    ENV['GOOGLE_ANALYTICS_PROPERTY_ID'] = '999999999'
    Apartment::Tenant.switch!(account_c.tenant)

    expect(Hyrax::Analytics.config.analytics_id).to eq(global_id)
    expect(Hyrax::Analytics.config.property_id).to eq('999999999')
  end

  it "keeps the current tenant's settings after another tenant's account loads" do
    account_a.update!(contact_email: 'a@tenant-a.example')
    account_b.update!(contact_email: 'b@tenant-b.example')
    Apartment::Tenant.switch!(account_a.tenant)
    Account.find(account_b.id)

    expect(Hyrax::Analytics.config.analytics_id).to eq('G-TENANTAAAA')
    expect(Hyrax::Analytics.config.property_id).to eq('111111111')
    expect(Hyrax.config.contact_email).to eq('a@tenant-a.example')
  end
end
