# frozen_string_literal: true

RSpec.describe Hyku::DataCiteCredentialStore do
  subject(:store) { described_class.new }

  let(:credentials) { store.fetch(provider: 'datacite') }

  describe 'in a multitenant install' do
    before { allow(Hyku).to receive(:single_tenant?).and_return(false) }

    context 'when the current tenant has a DataCite endpoint' do
      let(:endpoint) do
        DataCiteEndpoint.new(mode: 'test', prefix: '10.5072',
                             username: 'tenant-user', password: 'tenant-pass')
      end
      let(:account) { Account.new(data_cite_endpoint: endpoint) }

      before { allow(Site).to receive(:instance).and_return(Site.new(account: account)) }

      it "reads that tenant's credentials" do
        expect(credentials.prefix).to eq '10.5072'
        expect(credentials.username).to eq 'tenant-user'
        expect(credentials).to be_complete
      end
    end

    # The protection a consortial install depends on. Each tenant is a separate
    # institution, so inheriting an instance-wide account would mint one institution's
    # DOIs under another's prefix. A blank fieldset means this tenant does not mint.
    context 'when the current tenant has no credentials but the environment does' do
      before do
        allow(Site).to receive(:instance).and_return(Site.new(account: Account.new(data_cite_endpoint: DataCiteEndpoint.new)))
        stub_const('ENV', ENV.to_hash.merge('DATACITE_PREFIX' => '10.9999',
                                            'DATACITE_USERNAME' => 'instance-user',
                                            'DATACITE_PASSWORD' => 'instance-pass'))
      end

      it 'does not fall back to the environment' do
        expect(credentials.prefix).to be_blank
        expect(credentials.username).to be_blank
        expect(credentials).not_to be_complete
      end
    end

    context 'when there is no account at all' do
      before { allow(Site).to receive(:instance).and_return(nil) }

      it 'reports incomplete rather than raising' do
        expect { credentials }.not_to raise_error
        expect(credentials).not_to be_complete
      end
    end
  end

  # A single-tenant install has no proprietor route to store credentials in, so they come
  # from the environment as Solr and Fedora do.
  describe 'in a single-tenant install' do
    before { allow(Hyku).to receive(:single_tenant?).and_return(true) }

    context 'when the environment supplies credentials' do
      before do
        stub_const('ENV', ENV.to_hash.merge('DATACITE_PREFIX' => '10.9999',
                                            'DATACITE_USERNAME' => 'env-user',
                                            'DATACITE_PASSWORD' => 'env-pass',
                                            'DATACITE_MODE' => 'production'))
      end

      it 'reads them' do
        expect(credentials.prefix).to eq '10.9999'
        expect(credentials.username).to eq 'env-user'
        expect(credentials.mode).to eq :production
        expect(credentials).to be_complete
      end

      it 'ignores any account record, since one tenant means one configuration' do
        allow(Site).to receive(:instance).and_return(
          Site.new(account: Account.new(data_cite_endpoint: DataCiteEndpoint.new(prefix: '10.1111')))
        )

        expect(credentials.prefix).to eq '10.9999'
      end
    end

    context 'when the environment supplies nothing' do
      before do
        stub_const('ENV', ENV.to_hash.except('DATACITE_PREFIX', 'DATACITE_USERNAME',
                                             'DATACITE_PASSWORD', 'DATACITE_MODE'))
      end

      it 'reports incomplete rather than raising' do
        expect { credentials }.not_to raise_error
        expect(credentials).not_to be_complete
      end

      it 'defaults to the test environment, never production' do
        expect(credentials.mode).to eq :test
      end
    end
  end
end
