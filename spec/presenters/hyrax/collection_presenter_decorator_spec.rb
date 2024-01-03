# frozen_string_literal: true

RSpec.describe Hyrax::CollectionPresenter, type: :decorator do
  describe '.terms' do
    it 'does not include size' do
      expect(described_class.terms.size).to be_positive
      expect(described_class.terms).not_to include(:size)
    end
  end
end
