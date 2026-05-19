# frozen_string_literal: true
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

    context "when the id is not in the authority" do
      it "falls back to the id" do
        expect(described_class.label("not-a-known-hazard")).to eq "not-a-known-hazard"
      end
    end
  end

  describe ".active?" do
    it "is true for a known term" do
      expect(described_class.active?("Flashing")).to be true
    end

    it "is false for an id not in the authority" do
      expect(described_class.active?("not-a-known-hazard")).to be false
    end
  end

  describe ".include_current_value" do
    let(:render_opts) { [] }
    let(:html_opts)   { { class: 'moomin' } }

    it "preserves an off-authority value as a forced-select option" do
      expect(described_class.include_current_value("not-a-known-hazard", :idx, render_opts, html_opts))
        .to eq [[['not-a-known-hazard', 'not-a-known-hazard']], { class: 'moomin force-select' }]
    end

    it "leaves the options untouched for a known term" do
      expect(described_class.include_current_value("Flashing", :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end

    it "leaves the options untouched when the value is blank" do
      expect(described_class.include_current_value("", :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
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
