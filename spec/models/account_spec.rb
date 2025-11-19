# frozen_string_literal: true

RSpec.describe Account, type: :model do
  subject(:account) { Account.new }

  let(:cache_enabled) { false }

  describe '.tenants' do
    context 'when tenant_list param is nil' do
      it 'calls Account.all' do
        expect(Account).to receive(:all)
        described_class.tenants(nil)
      end
    end

    context 'when tenant_list param is empty' do
      it 'calls Account.all' do
        expect(Account).to receive(:all)
        described_class.tenants([])
      end
    end

    context 'when tenant_list param is a string' do
      it 'calls Account.where' do
        account = class_double(Account)
        expect(Account).to receive(:joins).with(:domain_names).and_return(account)
        expect(account).to receive(:where).with(domain_names: { cname: 'foo bar baz' })
        described_class.tenants('foo bar baz')
      end
    end
  end

  describe '.from_request' do
    let(:request) { double(host: 'example.com') }
    let(:noncanonical_request) { double(host: 'example.com.') }
    let!(:account) do
      described_class.create(name: 'example', tenant: '9cd18c23-c7a6-4d76-aab0-533ec3dc02a8', cname: 'example.com')
    end

    it 'retrieves the account that matches the incoming request' do
      expect(described_class.from_request(request)).to eq account
    end

    it 'canonicalizes the incoming request hostname' do
      expect(described_class.from_request(noncanonical_request)).to eq account
    end
  end

  describe '.default_cname' do
    it 'chokes on trailing dots' do
      expect { described_class.default_cname('foobar.') }.to raise_error ArgumentError
      # Important because we otherwise allow cname collision by treating "foobar." and "foobar-" equivalently
    end

    it 'returns canonicalized value' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('HYKU_DEFAULT_HOST', anything).and_return("%{tenant}.DEMO.hydrainabox.org.")
      expect(described_class.default_cname('foobar')).to eq 'foobar.demo.hydrainabox.org'
      expect(described_class.default_cname('fooBAR')).to eq 'foobar.demo.hydrainabox.org'
      expect(described_class.default_cname('ONE.two.3')).to eq 'one-two-3.demo.hydrainabox.org'
    end
  end

  describe '.canonical_cname' do
    it 'lowercases and strips trailing dots' do
      expect(described_class.canonical_cname('foobar')).to eq 'foobar'
      expect(described_class.canonical_cname('fooBAR...')).to eq 'foobar'
      expect(described_class.canonical_cname('ONE.two.3')).to eq 'one.two.3'
    end
  end

  describe '.admin_host' do
    it 'uses the configured setting' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('HYKU_ADMIN_HOST', anything).and_return('admin-host')
      expect(described_class.admin_host).to eq 'admin-host'
    end

    it 'falls back to the HOST environment variable' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('HYKU_ADMIN_HOST', anything).and_return(nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('HOST').and_return('system-host')
      expect(described_class.admin_host).to eq 'system-host'
      allow(ENV).to receive(:[]).and_call_original # "un-stub" ENV
    end

    it 'falls back to localhost' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('HYKU_ADMIN_HOST', anything).and_return(nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('HOST').and_return(nil)
      expect(described_class.admin_host).to eq 'localhost'
      allow(ENV).to receive(:[]).and_call_original # "un-stub" ENV
    end
  end

  describe '#switch!' do
    let!(:old_default_index) { Blacklight.default_index }

    before do
      account.build_solr_endpoint(url: 'http://example.com/solr/')
      account.build_fcrepo_endpoint(url: 'http://example.com/fedora', base_path: '/dev')
      account.build_redis_endpoint(namespace: 'foobaz')
      account.build_data_cite_endpoint(mode: 'test', prefix: '10.1234', username: 'user123', password: 'pass123')
      account.settings[:cache_api] = cache_enabled
      allow(Redis.current).to receive(:id).and_return "redis://localhost:6379/0"
      account.switch!
    end

    after do
      account.reset!
    end

    it 'switches the DataCite connection' do
      expect(Hyrax::DOI::DataCiteRegistrar.mode).to eq 'test'
      expect(Hyrax::DOI::DataCiteRegistrar.prefix).to eq '10.1234'
      expect(Hyrax::DOI::DataCiteRegistrar.username).to eq 'user123'
      expect(Hyrax::DOI::DataCiteRegistrar.password).to eq 'pass123'
      expect(Rails.application.routes.default_url_options[:host]).to eq account.cname
    end

    context "when cache is enabled" do
      let(:cache_enabled) { true }

      it "uses Redis as a cache store" do
        expect(Rails.application.config.action_controller.perform_caching).to be_truthy
        expect(ActionController::Base.perform_caching).to be_truthy
        expect(Rails.application.config.cache_store).to include(:redis_cache_store)
      end

      it "reverts to using file store when cache is off" do
        account.settings[:cache_api] = false
        account.switch!
        expect(Rails.application.config.cache_store).to eq([:file_store, described_class::DEFAULT_FILE_CACHE_STORE])
      end
    end

    context "when cashe is disabled" do
      let(:cache_enabled) { false }

      it "uses the file store" do
        expect(Rails.application.config.action_controller.perform_caching).to be_falsey
        expect(ActionController::Base.perform_caching).to be_falsey
        expect(Rails.application.config.cache_store).to eq([:file_store, described_class::DEFAULT_FILE_CACHE_STORE])
      end
    end

    it 'switches the ActiveFedora solr connection' do
      expect(Hyrax::SolrService.connection.uri.to_s).to eq 'http://example.com/solr/'
    end

    it 'switches the ActiveFedora fcrepo connection' do
      expect(ActiveFedora.fedora.host).to eq 'http://example.com/fedora'
      expect(ActiveFedora.fedora.base_path).to eq '/dev'
    end

    it 'switches the Blacklight solr conection' do
      expect(Blacklight.connection_config[:url]).to eq 'http://example.com/solr/'
    end

    it 'switches the Redis namespace' do
      expect(Hyrax.config.redis_namespace).to eq 'foobaz'
    end
  end

  describe '#switch' do
    let!(:previous_solr_url) { Hyrax::SolrService.connection.uri.to_s }
    let!(:previous_redis_namespace) { 'hyrax' }
    let!(:previous_fedora_host) { ActiveFedora.fedora.host }
    let!(:previous_data_cite_mode) { Hyrax::DOI::DataCiteRegistrar.mode }
    let!(:previous_data_cite_prefix) { Hyrax::DOI::DataCiteRegistrar.prefix }
    let!(:previous_data_cite_username) { Hyrax::DOI::DataCiteRegistrar.username }
    let!(:previous_data_cite_password) { Hyrax::DOI::DataCiteRegistrar.password }
    let!(:previous_account_cname) { account.cname }

    before do
      subject.build_solr_endpoint(url: 'http://example.com/solr/')
      subject.build_fcrepo_endpoint(url: 'http://example.com/fedora', base_path: '/dev')
      subject.build_redis_endpoint(namespace: 'foobaz')
      subject.build_data_cite_endpoint(mode: 'test', prefix: '10.1234', username: 'user123', password: 'pass123')
    end

    after do
      subject.reset!
    end

    it 'switches to the account-specific connection' do
      expect(Hyrax::SolrService.connection.uri.to_s).not_to eq 'http://example.com/solr/'
      expect do
        subject.switch do
          expect(Hyrax::SolrService.connection.uri.to_s).to eq 'http://example.com/solr/'
          expect(ActiveFedora.fedora.host).to eq 'http://example.com/fedora'
          expect(ActiveFedora.fedora.base_path).to eq '/dev'
          expect(Hyrax.config.redis_namespace).to eq 'foobaz'
          expect(Hyrax::DOI::DataCiteRegistrar.mode).to eq 'test'
          expect(Hyrax::DOI::DataCiteRegistrar.prefix).to eq '10.1234'
          expect(Hyrax::DOI::DataCiteRegistrar.username).to eq 'user123'
          expect(Hyrax::DOI::DataCiteRegistrar.password).to eq 'pass123'
          expect(Rails.application.routes.default_url_options[:host]).to eq account.cname
        end
      end.not_to change { Hyrax::SolrService.connection.uri.to_s }
    end

    it 'resets the active connections back to the defaults' do
      subject.switch do
        # no-op
      end
      expect(Hyrax::SolrService.connection.uri.to_s).to eq previous_solr_url
      expect(ActiveFedora.fedora.host).to eq previous_fedora_host
      expect(Hyrax.config.redis_namespace).to eq previous_redis_namespace
      # datacite mode is reset to test in between for safety.
      expect(Hyrax::DOI::DataCiteRegistrar.mode).to eq :test
      expect(Hyrax::DOI::DataCiteRegistrar.prefix).to eq previous_data_cite_prefix
      expect(Hyrax::DOI::DataCiteRegistrar.username).to eq previous_data_cite_username
      expect(Hyrax::DOI::DataCiteRegistrar.password).to eq previous_data_cite_password
      expect(Rails.application.routes.default_url_options[:host]).to eq previous_account_cname
    end

    context 'with missing endpoint' do
      it 'returns a NilSolrEndpoint' do
        subject.solr_endpoint = nil
        expect(subject.solr_endpoint).to be_kind_of NilSolrEndpoint
        subject.switch do
          expect { Hyrax::SolrService.connection.get 'foo' }.to raise_error RSolr::Error::ConnectionRefused
        end
      end

      it 'returns a NilFcrepoEndpoint' do
        subject.fcrepo_endpoint = nil
        expect(subject.fcrepo_endpoint).to be_kind_of NilFcrepoEndpoint
        subject.switch do
          expect { ActiveFedora::Fedora.instance.connection.get 'foo' }.to raise_error Faraday::ConnectionFailed
        end
      end

      it 'returns a NilRedisEndpoint' do
        subject.redis_endpoint = nil
        expect(subject.redis_endpoint).to be_kind_of NilRedisEndpoint
        subject.switch do
          expect(Hyrax.config.redis_namespace).to eq 'nil_redis_endpoint'
        end
      end

      it 'returns a NilDataCiteEndpoint' do
        account.data_cite_endpoint = nil
        expect(account.data_cite_endpoint).to be_kind_of NilDataCiteEndpoint
        expect(account.data_cite_endpoint.persisted?).to eq false
        account.switch do
          expect(Hyrax::DOI::DataCiteRegistrar.mode).to eq nil
          expect(Hyrax::DOI::DataCiteRegistrar.prefix).to eq nil
          expect(Hyrax::DOI::DataCiteRegistrar.password).to eq nil
          expect(Hyrax::DOI::DataCiteRegistrar.username).to eq nil
          expect(Rails.application.routes.default_url_options[:host]).to eq nil
        end
      end
    end
  end

  describe '#save' do
    subject { FactoryBot.create(:sign_up_account) }

    it 'canonicalizes the account cname' do
      subject.domain_names.first.update cname: 'example.com.'
      expect(subject.domain_names.first.cname).to eq 'example.com'
    end
  end

  describe '#create' do
    it 'requires name when cname is absent' do
      account1 = described_class.create(tenant: 'example')
      expect(account1.errors).not_to be_empty
      expect(account1.errors.messages).to match a_hash_including(:name, :"domain_names.cname")
    end

    context 'default_host' do
      let(:account1) { described_class.create(tenant: '5c0a372d-8b77-4943-af65-8a0f00ca5708', name: 'example') }

      context 'is set' do
        it 'builds default cname from name and default_host' do
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with('HYKU_DEFAULT_HOST', anything).and_return("%{tenant}.dev")
          expect(account1.errors).to be_empty
          expect(account1.domain_names.first.cname).to eq('example.dev')
        end
      end

      context 'is unset' do
        around do |example|
          default = ENV['HYKU_DEFAULT_TENANT']
          example.run
          ENV['HYKU_DEFAULT_TENANT'] = default
        end

        it 'builds default cname from name and admin_host' do
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with('HYKU_ADMIN_HOST', anything).and_return('admin-host')
          expect(account1.errors).to be_empty
          expect(account1.domain_names.first.cname).to eq('example.admin-host')
        end
      end
    end

    describe 'prevents duplicate cname and tenant values' do
      let!(:account1) do
        described_class.create(name: 'example', tenant: 'f84e8abf-8833-4ecd-a163-c720476fbfa8', cname: 'example.dev')
      end

      it 'on create' do
        account2 = described_class.create(name: 'example',
                                          tenant: 'f84e8abf-8833-4ecd-a163-c720476fbfa8',
                                          cname: 'example.dev')
        expect(account1.errors).to be_empty
        expect(account2.errors).not_to be_empty
        expect(account2.errors.messages).to match a_hash_including(:tenant, :name, :"domain_names.cname")
      end
      it 'on save' do
        account2 = described_class.new(tenant: 'c2168c56-1d71-4314-be63-6b54bcad4a2e', cname: account1.cname)
        expect(account2.save).to be_falsey
        expect(account2.errors).not_to be_empty
        expect(account2.errors.messages).to match a_hash_including(:name, :"domain_names.cname")
      end
    end

    it 'prevents duplicate cname from only name' do
      account1 = described_class.create(name: 'example')
      account2 = described_class.create(name: 'example')
      expect(account1.errors).to be_empty
      expect(account2.errors).not_to be_empty
      expect(account2.errors.messages).to match a_hash_including(:name, :"domain_names.cname")
    end

    it 'prevents conflicting new object saves' do
      described_class.create(name: 'example')
      account2 = described_class.new(name: 'example')
      expect(account2.save).to be false
      expect(account2.errors).to match a_hash_including(:"domain_names.cname")
    end

    describe 'guarantees only one account can reference the same' do
      let(:endpoint) { SolrEndpoint.create(url: 'solr') }
      let!(:account1) { described_class.create(name: 'example', solr_endpoint: endpoint) }

      it 'solr_endpoint' do
        account2 = described_class.new(name: 'other', solr_endpoint: endpoint)
        expect { account2.save }.to raise_error(ActiveRecord::RecordNotUnique)
        # NOTE: this is different than just populating account2.errors, because it is a FK
      end
    end
  end

  describe '#admin_emails' do
    let!(:account) { FactoryBot.create(:account, tenant: "59500a46-b1fb-412d-94d6-b928e91ef4d9") }

    before do
      Site.update(account:)
      Site.instance.admin_emails = ["test@test.com", "test@test.org"]
    end

    it 'switches to current tenant database and returns Site admin_emails' do
      expect(Apartment::Tenant).to receive(:switch).with(account.tenant).and_yield
      expect(account.admin_emails).to match_array(["test@test.com", "test@test.org"])
    end
  end

  describe '#admin_emails=' do
    let!(:account) { FactoryBot.create(:account, tenant: "02839e1d-b4a4-451a-ab83-4b8968621f1e") }

    before do
      Site.update(account:)
      Site.instance.admin_emails = ["test@test.com", "test@test.org"]
    end

    it 'switches to current tenant database updates Site admin_emails' do
      expect(Apartment::Tenant).to receive(:switch).with(account.tenant).exactly(3).times.and_yield
      expect(account.admin_emails).to match_array(["test@test.com", "test@test.org"])
      account.admin_emails = ["newadmin@here.org"]
      expect(account.admin_emails).to match_array(["newadmin@here.org"])
    end
  end

  describe '#global_tenant?' do
    subject { described_class.global_tenant? }

    context 'default setting for test environment' do
      it { is_expected.to be false }
    end

    context 'single tenant in production environment' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('HYKU_MULTITENANT', anything).and_return(false)
        allow(Rails.env).to receive(:test?).and_return false
      end

      it { is_expected.to be false }
    end

    context 'default tenant in a multitenant production environment' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('HYKU_MULTITENANT', anything).and_return(true)
        allow(Rails.env).to receive(:test?).and_return false
        allow(Apartment::Tenant).to receive(:current).and_return Apartment::Tenant.default_tenant
      end

      it { is_expected.to be true }
    end
  end

  describe 'is_public' do
    context 'it can change from public to not public' do
      let(:public_account) { FactoryBot.create(:account, tenant: "c3034b09-1913-4f76-a0c6-d0c43ecd3bfc") }

      it 'defaults to false' do
        expect(public_account.is_public).to be false
      end

      it 'can change to true' do
        public_account.is_public = true
        expect(public_account.is_public).to be true
      end
    end
  end

  describe 'Settings Customisations' do
    let(:account) { build(:account) }

    context 'settings jsonb keys' do
      it 'has contact_email key that is not empty' do
        expect(account.settings['contact_email']).to eq 'abc@abc.com'
        expect(account.settings['contact_email']).to be_an_instance_of(String)
      end

      it "has key weekly_email_list" do
        expect(account.settings['weekly_email_list']).to  eq ['aaa@aaa.com', 'bbb@bl.uk']
        expect(account.settings['weekly_email_list']).to be_an_instance_of(Array)
      end

      it "has non empty month_email_list" do
        expect(account.settings['monthly_email_list']).to  eq ['aaa@aaa.com', 'bbb@bl.uk']
        expect(account.settings['monthly_email_list']).to be_an_instance_of(Array)
      end

      it "has non empty yearly_email_list" do
        expect(account.settings['yearly_email_list']).to  eq ['aaa@aaa.com', 'bbb@bl.uk']
        expect(account.settings['yearly_email_list']).to be_an_instance_of(Array)
      end

      it "has google_scholarly_work_types" do
        expect(account.google_scholarly_work_types).to  eq ['Article', 'Book', 'ThesisOrDissertation', 'BookChapter']
        expect(account.google_scholarly_work_types).to be_an_instance_of(Array)
        expect(account.google_scholarly_work_types).to include('Book')
      end
    end

    context "settings from environment variable" do
      it "check all boolean truthy values" do
        ['allow_signup', "shared_login"].each do |key|
          expect(account.settings[key]).to eq('true')
        end
      end

      it "contains gtm_id" do
        expect(account.settings['gtm_id']).to eq 'GTM-123456'
      end

      it "allows GA4 google_analytics_id" do
        expect(account.settings['google_analytics_id']).to eq 'G-1234567890'
      end

      it "allows G4A google_analytics_id" do
        account.settings['google_analytics_id'] = 'G-ABCDE12345'
        expect(account.settings['google_analytics_id']).to eq 'G-ABCDE12345'
      end

      it "contains email_format" do
        expect(account.settings['email_format']).to include('@pacificu.edu')
      end
    end
  end

  describe "valid?" do
    before do
      account.tenant = uuid
      account.valid?
    end

    context "with no tenant UUID" do
      let(:uuid) { nil }

      it "sets a valid tenant UUID" do
        expect(account.tenant).to be_present
        expect(account.errors[:tenant]).to be_empty
      end
    end

    context "with a valid tenant UUID" do
      let(:uuid) { SecureRandom.uuid }

      it "respects the existing tenant UUID" do
        expect(account.tenant).to eq uuid
        expect(account.errors[:tenant]).to be_empty
      end
    end

    context "with an invalid tenant UUID" do
      let(:uuid) { 'foo-bar' }

      it "respects the existing tenant UUID" do
        expect(account.tenant).to eq uuid
      end

      it "is invalid" do
        expect(account.errors[:tenant]).not_to be_empty
      end
    end
  end

  describe "public_settings" do
    before do
      Account.private_settings.each do |setting|
        account.settings[setting] = ["foo"]
      end
    end

    it "excludes private settings" do
      Account.private_settings do |setting|
        expect(account.public_settings).not_to include(setting)
      end
    end
  end

  describe "smtp_settings" do
    context "with an existing account" do
      let!(:account) { create :account, smtp_settings: { authentication: "login" } }

      it "respects the existing settings" do
        expect(account.reload.smtp_settings.with_indifferent_access).to include(authentication: "login")
      end

      it "adds missing smtp config keys" do
        settings = Account.find(account.id).reload.smtp_settings

        PerTenantSmtpInterceptor.available_smtp_fields.each do |setting_name|
          expect(settings).to have_key(setting_name)
        end
      end
    end
  end

  describe 'cross tenant shared search' do
    context 'settings keys' do
      it 'has default value for #shared_search' do
        expect(account.search_only).to eq false
      end
    end

    context 'boolean method checks' do
      it '#shared_search_tenant? defaults to false' do
        expect(account).not_to be_search_only
      end
    end

    # NEW: Add validation specs
    context 'search-only validation' do
      let(:normal_account) { create(:account) }

      it 'is invalid when search_only is true and no full accounts are selected' do
        search_account = build(:account, search_only: true)
        expect(search_account).not_to be_valid
        expect(search_account.errors[:base]).to include('Search-only accounts must have at least one full account selected for cross-tenant search')
      end

      it 'is valid when search_only is true and at least one full account is selected' do
        search_account = build(:account, search_only: true, full_account_ids: [normal_account.id])
        expect(search_account).to be_valid
      end

      it 'is valid when search_only is false with no full accounts' do
        regular_account = build(:account, search_only: false)
        expect(regular_account).to be_valid
      end

      it 'allows removing all full accounts if search_only is changed to false' do
        cross_search_solr = create(:solr_endpoint, url: "http://solr:8983/solr/hydra-cross-search-tenant")
        search_account = create(:account,
                               search_only: true,
                               full_account_ids: [normal_account.id],
                               solr_endpoint: cross_search_solr,
                               fcrepo_endpoint: nil)

        search_account.search_only = false
        search_account.full_account_ids = []
        expect(search_account).to be_valid
      end
    end

    context 'can add and remove Full Account from shared search' do
      let(:normal_account) { create(:account) }
      let(:cross_search_solr) { create(:solr_endpoint, url: "http://solr:8983/solr/hydra-cross-search-tenant") }

      let(:shared_search_account) do
        create(:account,
               search_only: true,
               full_account_ids: [normal_account.id],
               solr_endpoint: cross_search_solr,
               fcrepo_endpoint: nil)
      end

      it 'contains full_account' do
        expect(shared_search_account.full_accounts).to be_truthy
        expect(shared_search_account.full_accounts.size).to eq 1
      end

      it 'removes full_account' do
        shared_search_account.full_account_ids = []
        expect(shared_search_account.full_accounts.size).to eq 0
      end
    end
  end

  describe '#find_or_schedule_jobs' do
    let(:account) { create(:account) }
    let(:site_account) { create(:account) }

    before do
      allow(Site).to receive(:account).and_return(site_account)
      allow(AccountElevator).to receive(:switch!)
    end

    it 'schedules default jobs' do
      expect(EmbargoAutoExpiryJob).to receive(:perform_later)
      expect(LeaseAutoExpiryJob).to receive(:perform_later)

      account.find_or_schedule_jobs
    end

    it 'does not schedule jobs that already exist' do
      allow(account).to receive(:find_job).with(EmbargoAutoExpiryJob).and_return(true)
      allow(account).to receive(:find_job).with(LeaseAutoExpiryJob).and_return(true)

      expect(EmbargoAutoExpiryJob).not_to receive(:perform_later)
      expect(LeaseAutoExpiryJob).not_to receive(:perform_later)

      account.find_or_schedule_jobs
    end

    context 'with batch email notifications enabled' do
      before do
        account.settings['batch_email_notifications'] = true
        # Stub default jobs to prevent the error
        allow(account).to receive(:find_job).with(EmbargoAutoExpiryJob).and_return(false)
        allow(account).to receive(:find_job).with(LeaseAutoExpiryJob).and_return(false)
      end

      it 'schedules BatchEmailNotificationJob' do
        allow(account).to receive(:find_job).with(BatchEmailNotificationJob).and_return(false)
        expect(BatchEmailNotificationJob).to receive(:perform_later)
        account.find_or_schedule_jobs
      end

      it 'does not schedule if job already exists' do
        allow(account).to receive(:find_job).with(BatchEmailNotificationJob).and_return(true)
        expect(BatchEmailNotificationJob).not_to receive(:perform_later)
        account.find_or_schedule_jobs
      end
    end

    context 'with analytics enabled' do
      before do
        account.settings['analytics'] = true
        allow(Hyrax.config).to receive(:analytics_reporting?).and_return(true)
      end

      it 'schedules UserStatCollectionJob' do
        expect(UserStatCollectionJob).to receive(:perform_later)
        account.find_or_schedule_jobs
      end

      context 'with depositor email notifications enabled' do
        before do
          account.settings['depositor_email_notifications'] = true
        end

        it 'schedules DepositorEmailNotificationJob' do
          expect(DepositorEmailNotificationJob).to receive(:perform_later)
          account.find_or_schedule_jobs
        end
      end
    end

    it 'switches back to original account' do
      expect(AccountElevator).to receive(:switch!).with(account)
      expect(AccountElevator).to receive(:switch!).with(site_account)

      account.find_or_schedule_jobs
    end

    it 'resets when no original account exists' do
      allow(Site).to receive(:account).and_return(nil)
      expect(account).to receive(:reset!)

      account.find_or_schedule_jobs
    end
  end
end
