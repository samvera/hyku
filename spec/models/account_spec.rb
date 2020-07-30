# frozen_string_literal: true

RSpec.describe Account, type: :model do
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
        expect(Account).to receive(:where).with(cname: 'foo bar baz')
        described_class.tenants('foo bar baz')
      end
    end
  end

  describe '.from_request' do
    let(:request) { double(host: 'example.com') }
    let(:noncanonical_request) { double(host: 'example.com.') }
    let!(:account) { described_class.create(name: 'example', tenant: 'example', cname: 'example.com') }

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
      allow(Settings.multitenancy).to receive(:default_host).and_return("%{tenant}.DEMO.hydrainabox.org.")
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
      allow(Settings.multitenancy).to receive(:admin_host).and_return('admin-host')
      expect(described_class.admin_host).to eq 'admin-host'
    end

    it 'falls back to the HOST environment variable' do
      allow(Settings.multitenancy).to receive(:admin_host).and_return(nil)
      allow(ENV).to receive(:[]).with('HOST').and_return('system-host')
      expect(described_class.admin_host).to eq 'system-host'
    end

    it 'falls back to localhost' do
      allow(Settings.multitenancy).to receive(:admin_host).and_return(nil)
      allow(ENV).to receive(:[]).with('HOST').and_return(nil)
      expect(described_class.admin_host).to eq 'localhost'
    end
  end

  describe '#switch!' do
    let!(:old_default_index) { Blacklight.default_index }

    before do
      subject.build_solr_endpoint(url: 'http://example.com/solr/')
      subject.build_fcrepo_endpoint(url: 'http://example.com/fedora', base_path: '/dev')
      subject.build_redis_endpoint(namespace: 'foobaz')
      subject.switch!
    end

    after do
      subject.reset!
    end

    it 'switches the ActiveFedora solr connection' do
      expect(ActiveFedora::SolrService.instance.conn.uri.to_s).to eq 'http://example.com/solr/'
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
    let!(:previous_solr_url) { ActiveFedora::SolrService.instance.conn.uri.to_s }
    let!(:previous_redis_namespace) { 'hyku' }
    let!(:previous_fedora_host) { ActiveFedora.fedora.host }

    before do
      subject.build_solr_endpoint(url: 'http://example.com/solr/')
      subject.build_fcrepo_endpoint(url: 'http://example.com/fedora', base_path: '/dev')
      subject.build_redis_endpoint(namespace: 'foobaz')
    end

    after do
      subject.reset!
    end

    it 'switches to the account-specific connection' do
      subject.switch do
        expect(ActiveFedora::SolrService.instance.conn.uri.to_s).to eq 'http://example.com/solr/'
        expect(ActiveFedora.fedora.host).to eq 'http://example.com/fedora'
        expect(ActiveFedora.fedora.base_path).to eq '/dev'
        expect(Hyrax.config.redis_namespace).to eq 'foobaz'
      end
    end

    it 'resets the active connections back to the defaults' do
      subject.switch do
        # no-op
      end
      expect(ActiveFedora::SolrService.instance.conn.uri.to_s).to eq previous_solr_url
      expect(ActiveFedora.fedora.host).to eq previous_fedora_host
      expect(Hyrax.config.redis_namespace).to eq previous_redis_namespace
    end

    context 'with missing endpoint' do
      it 'returns a NilSolrEndpoint' do
        subject.solr_endpoint = nil
        expect(subject.solr_endpoint).to be_kind_of NilSolrEndpoint
        subject.switch do
          expect { ActiveFedora::SolrService.instance.conn.get 'foo' }.to raise_error RSolr::Error::ConnectionRefused
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
    end
  end

  describe '#save' do
    subject { FactoryBot.create(:sign_up_account) }

    it 'canonicalizes the account cname' do
      subject.update cname: 'example.com.'
      expect(subject.cname).to eq 'example.com'
    end
  end

  describe '#create' do
    it 'requires name when cname is absent' do
      account1 = described_class.create(tenant: 'example')
      expect(account1.errors).not_to be_empty
      expect(account1.errors.messages).to match a_hash_including(:name, :cname)
    end

    it 'does not require name when cname is present' do
      account1 = described_class.create(tenant: 'example', cname: 'example.com')
      expect(account1.errors).to be_empty
    end

    context 'default_host' do
      let(:account1) { described_class.create(tenant: 'example', name: 'example') }

      context 'is set' do
        it 'builds default cname from name and default_host' do
          allow(Settings.multitenancy).to receive(:default_host).and_return "%{tenant}.dev"
          expect(account1.errors).to be_empty
          expect(account1.cname).to eq('example.dev')
        end
      end

      context 'is unset' do
        it 'builds default cname from name and admin_host' do
          original = Settings.multitenancy.default_host
          Settings.multitenancy.default_host = nil
          allow(Settings.multitenancy).to receive(:admin_host).and_return('admin-host')
          expect(account1.errors).to be_empty
          expect(account1.cname).to eq('example.admin-host')
          Settings.multitenancy.default_host = original
        end
      end
    end

    describe 'prevents duplicate cname and tenant values' do
      let!(:account1) { described_class.create(name: 'example', tenant: 'example_tenant', cname: 'example.dev') }

      it 'on create' do
        account2 = described_class.create(name: 'example', tenant: 'example_tenant', cname: 'example.dev')
        expect(account1.errors).to be_empty
        expect(account2.errors).not_to be_empty
        expect(account2.errors.messages).to match a_hash_including(:tenant, :cname)
        expect(account2.errors.messages).not_to include(:name)
      end
      it 'on save' do
        account2 = described_class.new(tenant: 'other_tenant', cname: account1.cname)
        expect(account2.save).to be_falsey
        expect(account2.errors).not_to be_empty
        expect(account2.errors.messages).to match a_hash_including(:cname)
      end
    end

    it 'prevents duplicate cname from only name' do
      account1 = described_class.create(name: 'example')
      account2 = described_class.create(name: 'example')
      expect(account1.errors).to be_empty
      expect(account2.errors).not_to be_empty
      expect(account2.errors.messages).to match a_hash_including(:cname)
      expect(account2.errors.messages).not_to include(:name)
    end

    it 'prevents conflicting new object saves' do
      described_class.create(name: 'example')
      account2 = described_class.new(name: 'example')
      expect(account2.save).to be false
      expect(account2.errors).to match a_hash_including(:cname)
    end

    describe 'guarantees only one account can reference the same' do
      let(:endpoint) { SolrEndpoint.create(url: 'solr') }
      let!(:account1) { described_class.create(name: 'example', solr_endpoint: endpoint) }

      it 'solr_endpoint' do
        account2 = described_class.new(name: 'other', solr_endpoint: endpoint)
        expect { account2.save }.to raise_error(ActiveRecord::RecordNotUnique)
        # Note: this is different than just populating account2.errors, because it is a FK
      end
    end
  end

  describe '#admin_emails' do
    let!(:account) { FactoryBot.create(:account, tenant: "mytenant") }

    before do
      Site.update(account: account)
      Site.instance.admin_emails = ["test@test.com", "test@test.org"]
    end

    it 'switches to current tenant database and returns Site admin_emails' do
      expect(Apartment::Tenant).to receive(:switch).with(account.tenant).and_yield
      expect(account.admin_emails).to match_array(["test@test.com", "test@test.org"])
    end
  end

  describe '#admin_emails=' do
    let!(:account) { FactoryBot.create(:account, tenant: "mytenant") }

    before do
      Site.update(account: account)
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
        allow(Settings.multitenancy).to receive(:enabled).and_return false
        allow(Rails.env).to receive(:test?).and_return false
      end

      it { is_expected.to be false }
    end

    context 'default tenant in a multitenant production environment' do
      before do
        allow(Settings.multitenancy).to receive(:enabled).and_return true
        allow(Rails.env).to receive(:test?).and_return false
        allow(Apartment::Tenant).to receive(:current_tenant).and_return Apartment::Tenant.default_tenant
      end

      it { is_expected.to be true }
    end
  end
end
