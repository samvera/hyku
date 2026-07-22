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

    it 'offers parent and collection connect by default (config settings, on)' do
      expect(config.parent_connect?).to be(true)
      expect(config.collection_connect?).to be(true)
    end
  end

  describe 'parent/collection connect (config settings, not flags)' do
    it 'reflects the assigned config values' do
      config = described_class.new do |c|
        c.parent_connect = false
        c.collection_connect = false
      end

      expect(config.parent_connect?).to be(false)
      expect(config.collection_connect?).to be(false)
    end
  end

  describe 'capabilities (guided/standard enable flags)' do
    subject(:capabilities) { described_class.new.capabilities }

    def stub_flags(guided: false, standard: false)
      allow(Flipflop).to receive(:enable_guided_deposit?).and_return(guided)
      allow(Flipflop).to receive(:enable_standard_deposit?).and_return(standard)
    end

    context 'when neither enable flag is set' do
      before { stub_flags }

      it 'is disabled; guided-dependent capabilities are inert' do
        expect(capabilities).not_to be_enabled
        expect(capabilities).not_to be_guided_replaces_standard
        expect(capabilities).not_to be_standard_deposit_button
        expect(capabilities).not_to be_standard_link
      end
    end

    context 'with enable_standard_deposit only (the default)' do
      before { stub_flags(standard: true) }

      it 'shows the standard button but does not enable or replace with guided' do
        expect(capabilities).to be_standard_deposit_button
        expect(capabilities).not_to be_enabled
        expect(capabilities).not_to be_guided_replaces_standard
      end
    end

    context 'with enable_guided_deposit on (only)' do
      before { stub_flags(guided: true) }

      it 'enables guided and overrides the standard entry links' do
        expect(capabilities).to be_enabled
        expect(capabilities).to be_guided_replaces_standard
      end

      it 'does not show the standard button, nor the standard-form link' do
        expect(capabilities).not_to be_standard_deposit_button
        expect(capabilities).not_to be_standard_link
      end
    end

    context 'with both enable flags on' do
      before { stub_flags(guided: true, standard: true) }

      it 'shows both buttons; guided still overrides the entry links' do
        expect(capabilities).to be_enabled
        expect(capabilities).to be_standard_deposit_button
        expect(capabilities).to be_guided_replaces_standard
      end

      it 'offers the standard-form link on the guided start screen' do
        expect(capabilities).to be_standard_link
      end
    end
  end

  describe 'depositor sharing (config setting, gated by guided being enabled)' do
    it 'is available by default when guided is enabled' do
      allow(Flipflop).to receive(:enable_guided_deposit?).and_return(true)
      expect(described_class.new).to be_sharing
    end

    it 'is off when the config setting is disabled' do
      allow(Flipflop).to receive(:enable_guided_deposit?).and_return(true)
      config = described_class.new { |c| c.depositor_sharing = false }
      expect(config).not_to be_sharing
    end

    it 'is off when guided is not enabled, regardless of the setting' do
      allow(Flipflop).to receive(:enable_guided_deposit?).and_return(false)
      expect(described_class.new).not_to be_sharing
    end
  end

  describe 'parent-connect placement' do
    subject(:config) { described_class.new { |c| c.parent_connect_placement = placement } }

    let(:placement) { :both }

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

    context 'when parent-connect is turned off in config' do
      subject(:config) do
        described_class.new do |c|
          c.parent_connect_placement = placement
          c.parent_connect = false
        end
      end

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
