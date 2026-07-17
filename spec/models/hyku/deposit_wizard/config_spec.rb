# frozen_string_literal: true

RSpec.describe Hyku::DepositWizard::Config do
  describe 'defaults (bare Hyku)' do
    subject(:config) { described_class.new }

    it 'is a flat, no-container wizard' do
      expect(config.container_type).to be_nil
      expect(config).not_to be_container
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

  describe 'capabilities (live per-tenant Flipflop reads)' do
    subject(:config) { described_class.new }

    it 'reads each capability straight from its Flipflop feature' do
      allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
      allow(Flipflop).to receive(:deposit_wizard_collection_connect?).and_return(false)
      allow(Flipflop).to receive(:deposit_wizard_sharing?).and_return(true)

      expect(config.capabilities.parent_connect?).to be(true)
      expect(config.capabilities.collection_connect?).to be(false)
      expect(config.capabilities.sharing?).to be(true)
    end

    it 'reflects a flag change immediately (no stored state to shadow it)' do
      allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(false)
      expect(config.capabilities.parent_connect?).to be(false)

      allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true)
      expect(config.capabilities.parent_connect?).to be(true)
    end
  end

  describe 'parent-connect placement' do
    subject(:config) { described_class.new { |c| c.parent_connect_placement = placement } }

    let(:placement) { :both }

    before { allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(true) }

    context 'with the default (:both)' do
      it 'offers parent selection on both edges' do
        expect(config.parent_connect_placement).to eq(:both)
        expect(config).to be_parent_connect_on_start
        expect(config).to be_parent_connect_on_review
      end
    end

    context 'with :start' do
      let(:placement) { :start }

      it 'offers it only up front' do
        expect(config).to be_parent_connect_on_start
        expect(config).not_to be_parent_connect_on_review
      end
    end

    context 'with :review' do
      let(:placement) { :review }

      it 'offers it only on review' do
        expect(config).not_to be_parent_connect_on_start
        expect(config).to be_parent_connect_on_review
      end
    end

    context 'with :none' do
      let(:placement) { :none }

      it 'offers it on neither edge' do
        expect(config).not_to be_parent_connect_on_start
        expect(config).not_to be_parent_connect_on_review
      end
    end

    context 'when the parent-connect flag is off' do
      before { allow(Flipflop).to receive(:deposit_wizard_parent_connect?).and_return(false) }

      it 'shows nothing regardless of placement' do
        expect(config).not_to be_parent_connect_on_start
        expect(config).not_to be_parent_connect_on_review
      end
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

    context 'when the redirects feature is active' do
      before { allow(Hyrax.config).to receive(:redirects_active?).and_return(true) }

      it 'is hidden when the work does not carry the redirects attribute' do
        form = double(model: double(:model))
        expect(config.redirects_available?(form)).to be(false)
      end

      it 'is shown when the work carries the redirects attribute' do
        form = double(model: double(:model, redirects: []))
        expect(config.redirects_available?(form)).to be(true)
      end
    end
  end

  describe 'block configuration (downstream override)' do
    subject(:config) do
      described_class.new do |c|
        c.container_type = 'GenericWorkResource'
        c.item_types = %w[GenericWorkResource]
        c.suggestions = { image: %w[design installation] }
        c.post_commit = ->(_work, _wizard) {}
        c.parent_connect_placement = :review
        c.parent_types = %w[GenericWorkResource EtdResource OerResource]
      end
    end

    it 'applies the assigned values' do
      expect(config.container_type).to eq('GenericWorkResource')
      expect(config).to be_container
      expect(config.item_types).to eq(%w[GenericWorkResource])
      expect(config.suggestions).to eq(image: %w[design installation])
      expect(config.post_commit).to respond_to(:call)
      expect(config.parent_connect_placement).to eq(:review)
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
