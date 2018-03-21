require 'rails_helper'

RSpec.describe FileSet do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq FileSetIndexer }
  end
end
