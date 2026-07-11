# frozen_string_literal: true

RSpec.describe Hyku::DepositWizard::Config do
  describe 'defaults (bare Hyku)' do
    subject(:config) { described_class.new }

    it 'is a flat, no-container wizard' do
      expect(config.container_type).to be_nil
      expect(config).not_to be_container
    end

    it 'has the prototype behavior toggles off at the Hyku layer' do
      expect(config.single_admin_set).to be(true)
      expect(config.enable_batch).to be(false)
      expect(config.file_pool).to be(false)
      expect(config.file_meta).to be(false)
    end

    it 'has empty item types and suggestions and no post-commit hook' do
      expect(config.item_types).to be_nil
      expect(config.suggestions).to eq({})
      expect(config.post_commit).to be_nil
    end

    it 'has no parent_types restriction by default' do
      expect(config.parent_types).to be_nil
    end
  end

  describe 'per-tenant capability flags' do
    subject(:config) { described_class.new }

    it 'reads each capability from its Flipflop feature when no override is set' do
      allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
      allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(false)
      allow(Flipflop).to receive(:deposit_wizard_sharing?).and_return(true)

      expect(config.enable_parent_connect).to be(true)
      expect(config.enable_collection_connect).to be(false)
      expect(config.enable_sharing).to be(true)
    end

    it 'lets an explicit in-memory override win over the Flipflop feature' do
      allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(false)
      config.enable_parent_connect = true

      expect(config.enable_parent_connect).to be(true)
    end
  end

  describe '#redirects_available?' do
    subject(:config) { described_class.new }

    it 'mirrors Hyrax\'s own redirects gate (no separate wizard flag)' do
      allow(Hyrax.config).to receive(:redirects_active?).and_return(false)
      expect(config.redirects_available?).to be(false)

      allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
      expect(config.redirects_available?).to be(true)
    end
  end

  describe 'block configuration (downstream override)' do
    subject(:config) do
      described_class.new do |c|
        c.container_type = 'GenericWorkResource'
        c.file_pool = true
        c.file_meta = true
        c.suggestions = { image: %w[design installation] }
        c.post_commit = ->(_work, _wizard) {}
        c.enable_parent_connect = true
        c.parent_types = %w[GenericWorkResource EtdResource OerResource]
      end
    end

    it 'applies the assigned values' do
      expect(config.container_type).to eq('GenericWorkResource')
      expect(config).to be_container
      expect(config.file_pool).to be(true)
      expect(config.file_meta).to be(true)
      expect(config.suggestions).to eq(image: %w[design installation])
      expect(config.post_commit).to respond_to(:call)
      expect(config.enable_parent_connect).to be(true)
      expect(config.parent_types).to eq(%w[GenericWorkResource EtdResource OerResource])
    end
  end
end

RSpec.describe Hyku::DepositWizard do
  after { described_class.reset_config! }

  it 'defaults to a flat Config instance' do
    expect(described_class.config).to be_a(Hyku::DepositWizard::Config)
    expect(described_class.config).not_to be_container
  end

  it 'accepts a replacement config' do
    replacement = Hyku::DepositWizard::Config.new { |c| c.container_type = 'Portfolio' }
    described_class.config = replacement

    expect(described_class.config).to be(replacement)
    expect(described_class.config).to be_container
  end
end
