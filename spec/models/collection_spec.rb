# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Collection do
  it "is a hyrax collection" do
    expect(described_class.ancestors).to include Hyrax::CollectionBehavior
  end

  describe ".indexer" do
    subject { described_class.indexer }

    it { is_expected.to eq CollectionIndexer }
  end
end
