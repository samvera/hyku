# frozen_string_literal: true
RSpec.describe Hyrax::EducationLevelsService do
  describe "select_options" do
    subject { described_class.select_all_options }

    it "has a select list" do
      expect(subject.first).to eq ["Community college / Lower division", "Community college / Lower division"]
      expect(subject.size).to eq 5
    end
  end

  describe "label" do
    subject { described_class.label("Career / Technical") }

    it { is_expected.to eq 'Career / Technical' }
  end
end
