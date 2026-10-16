# frozen_string_literal: true

RSpec.describe Hyku::S3Migration do
  describe '.file_set_class' do
    it 'is the Valkyrie file set class Hyrax is configured with' do
      expect(described_class.file_set_class).to eq Hyrax.config.valkyrie_file_set_class
    end

    it 'follows a custom configured file set class' do
      custom = Class.new(Hyrax::FileSet)
      allow(Hyrax.config).to receive(:valkyrie_file_set_class).and_return(custom)

      expect(described_class.file_set_class).to eq custom
    end
  end
end
