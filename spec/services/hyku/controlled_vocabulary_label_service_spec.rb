# frozen_string_literal: true

RSpec.describe Hyku::ControlledVocabularyLabelService do
  subject(:service) { described_class.new }

  let(:vocabulary) do
    Qa::LocalAuthority.find_or_create_by!(name: 'dashboard_vocab') { |a| a.label = 'Dashboard Vocab' }
  end

  before do
    vocabulary.local_authority_entries.find_or_create_by!(uri: 'local_auth_123') do |entry|
      entry.label = 'Opaque Term'
      entry.active = true
    end
    service.reset!
  end

  after { service.reset! }

  describe '#resolvable?' do
    it 'accepts a vocabulary backed only by database rows' do
      expect(service.resolvable?('dashboard_vocab')).to be true
    end

    it 'still accepts a vocabulary shipped as a yaml file' do
      expect(service.resolvable?('licenses')).to be true
    end

    it 'rejects a name no vocabulary answers to' do
      expect(service.resolvable?('no_such_vocabulary')).to be false
    end

    it 'rejects a remote authority, which would cost a request per value' do
      allow(Hyrax::ControlledVocabularies).to receive(:remote_authorities).and_return('loc/subjects' => {})

      expect(service.resolvable?('loc/subjects')).to be false
    end
  end

  describe '#labels_for' do
    it 'resolves a dashboard-created term to its label' do
      expect(service.labels_for('dashboard_vocab', ['local_auth_123'])).to eq ['Opaque Term']
    end

    it 'keeps an unresolved value in place so the array stays index-aligned' do
      expect(service.labels_for('dashboard_vocab', ['nope', 'local_auth_123']))
        .to eq ['nope', 'Opaque Term']
    end

    # `populate_qa` seeds every yaml authority into the tables, so the database
    # branch answers first for all of them and the inherited yaml lookup is only
    # reachable with it stubbed away.
    it 'falls through to a vocabulary shipped as a yaml file' do
      allow(service).to receive(:database_backed?).and_return(false)

      expect(service.labels_for('media_viewer', ['universal_viewer'])).to eq ['Universal Viewer']
    end
  end

  # Two tenants can each hold a vocabulary of the same name with different terms,
  # so a cache entry keyed on the name alone answers one tenant with the other's
  # labels.
  describe 'tenant isolation' do
    it 'keys its cache per tenant' do
      expect(service.send(:cache_key, 'dashboard_vocab'))
        .to include(Apartment::Tenant.current.to_s)
    end

    it 'drops memoized maps when the tenant changes' do
      service.labels_for('dashboard_vocab', ['local_auth_123'])
      service.reset!

      expect(RequestStore.store[:hyku_controlled_vocabulary_label_maps]).to be_blank
    end

    it 'keys its memo per tenant, not per vocabulary name alone' do
      service.labels_for('dashboard_vocab', ['local_auth_123'])

      allow(Apartment::Tenant).to receive(:current).and_return('another_tenant')
      service.labels_for('dashboard_vocab', ['local_auth_123'])

      keys = RequestStore.store[:hyku_controlled_vocabulary_label_maps].keys

      expect(keys).to include('another_tenant-dashboard_vocab')
    end

    it 'does not share its memo between threads' do
      service.labels_for('dashboard_vocab', ['local_auth_123'])
      seen = nil

      Thread.new { seen = RequestStore.store[:hyku_controlled_vocabulary_label_maps] }.join

      expect(seen).to be_nil
    end
  end
end
