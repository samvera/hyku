# frozen_string_literal: true
RSpec.describe Hyrax::DisciplineService do
  describe "select_options" do
    subject { described_class.select_all_options }

    it "has a select list" do
      expect(subject.first).to eq ["Languages - Spanish", "Languages - Spanish"]
      expect(subject.size).to eq 65
    end
  end

  describe "label" do
    subject { described_class.label("Computing and Information - Computer Science") }

    it { is_expected.to eq 'Computing and Information - Computer Science' }
  end
end
