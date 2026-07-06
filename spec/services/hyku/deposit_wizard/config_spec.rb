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
  end

  describe 'block configuration (downstream override)' do
    subject(:config) do
      described_class.new do |c|
        c.container_type = 'Portfolio'
        c.file_pool = true
        c.file_meta = true
        c.suggestions = { image: %w[design installation] }
        c.post_commit = ->(_work, _wizard) {}
      end
    end

    it 'applies the assigned values' do
      expect(config.container_type).to eq('Portfolio')
      expect(config).to be_container
      expect(config.file_pool).to be(true)
      expect(config.file_meta).to be(true)
      expect(config.suggestions).to eq(image: %w[design installation])
      expect(config.post_commit).to respond_to(:call)
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
