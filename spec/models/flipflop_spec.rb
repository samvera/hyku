# frozen_string_literal: true

RSpec.describe Flipflop do
  describe "iiif_ranges?" do
    subject { described_class.iiif_ranges? }

    it "defaults to false" do
      is_expected.to be false
    end
  end
end
