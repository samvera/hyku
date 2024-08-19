# frozen_string_literal: true
RSpec.describe Hyrax::LearningResourceTypesService do
  describe "select_options" do
    subject { described_class.select_all_options }

    it "has a select list" do
      expect(subject.first).to eq ["Activity/lab", "Activity/lab"]
      expect(subject.size).to eq 15
    end
  end

  describe "label" do
    subject { described_class.label("Reading") }

    it { is_expected.to eq 'Reading' }
  end
end
