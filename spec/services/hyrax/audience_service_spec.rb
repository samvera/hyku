# frozen_string_literal: true
RSpec.describe Hyrax::AudienceService do
  describe "select_options" do
    subject { described_class.select_all_options }

    it "has a select list" do
      expect(subject.first).to eq ["Student", "Student"]
      expect(subject.size).to eq 3
    end
  end

  describe "label" do
    subject { described_class.label("Instructor") }

    it { is_expected.to eq 'Instructor' }
  end
end
