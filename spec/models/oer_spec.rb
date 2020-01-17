# Generated via
#  `rails generate hyrax:work Oer`
require 'rails_helper'

RSpec.describe Oer do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq OerIndexer }
  end
end
