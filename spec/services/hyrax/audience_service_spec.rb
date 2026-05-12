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

    context "when the id is not in the authority" do
      it "falls back to the id" do
        expect(described_class.label("not-a-known-audience")).to eq "not-a-known-audience"
      end
    end
  end

  describe "active?" do
    it "is true for a known term" do
      expect(described_class.active?("Instructor")).to be true
    end

    it "is false for an id not in the authority" do
      expect(described_class.active?("not-a-known-audience")).to be false
    end
  end

  describe "include_current_value" do
    let(:render_opts) { [] }
    let(:html_opts)   { { class: 'moomin' } }

    it "preserves an off-authority value as a forced-select option" do
      expect(described_class.include_current_value("not-a-known-audience", :idx, render_opts, html_opts))
        .to eq [[['not-a-known-audience', 'not-a-known-audience']], { class: 'moomin force-select' }]
    end

    it "leaves the options untouched for a known term" do
      expect(described_class.include_current_value("Instructor", :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end

    it "leaves the options untouched when the value is blank" do
      expect(described_class.include_current_value("", :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end
  end
end
