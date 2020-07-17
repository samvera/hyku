# Generated via
#  `rails generate hyrax:work Etd`
require 'rails_helper'

RSpec.describe Etd do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq EtdIndexer }
  end

end
