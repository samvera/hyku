RSpec.describe Hyrax::AccessibilityHazardsService do
  describe ".select_all_options" do
    subject { described_class.select_all_options }

    it "has a select list" do
      expect(subject.first).to eq ["Flashing", "Flashing"]
      expect(subject.size).to eq 4
    end
  end

  describe ".label" do
    subject { described_class.label("Flashing") }

    it "fetches the term" do
      expect(subject).to eq("Flashing")
    end
  end

  describe ".microdata_type" do
    subject { described_class.microdata_type(id) }

    context "when id is in the i18n" do
      let(:id) { "Flashing" }

      it "gives schema.org type" do
        expect(subject).to eq("http://schema.org/accessibilityHazard")
      end
    end

    context "when the id is not in the i18n" do
      let(:id) { "missing" }

      it "gives default type" do
        expect(subject).to eq(Hyrax.config.microdata_default_type)
      end
    end

    context "when id is nil" do
      let(:id) { nil }

      it "gives default type" do
        expect(subject).to eq(Hyrax.config.microdata_default_type)
      end
    end
  end
end
