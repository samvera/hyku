# frozen_string_literal: true
RSpec.describe Hyrax::OerTypesService do
  describe "select_options" do
    subject { described_class.select_all_options }

    it "has a select list" do
      expect(subject.first).to eq ["Collection", "Collection"]
      expect(subject.size).to eq 12
    end
  end

  describe "label" do
    subject { described_class.label("MovingImage") }

    it { is_expected.to eq 'MovingImage' }
  end
end
