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

    context "when the id is not in the authority" do
      it "falls back to the id" do
        expect(described_class.label("not-a-known-discipline")).to eq "not-a-known-discipline"
      end
    end
  end

  describe "active?" do
    it "is true for a known term (discipline authority has no active flag, so unflagged is active)" do
      expect(described_class.active?("Computing and Information - Computer Science")).to be true
    end

    it "is false for an id not in the authority" do
      expect(described_class.active?("not-a-known-discipline")).to be false
    end
  end

  describe "include_current_value" do
    let(:render_opts) { [] }
    let(:html_opts)   { { class: 'moomin' } }

    it "preserves an off-authority value as a forced-select option" do
      expect(described_class.include_current_value("not-a-known-discipline", :idx, render_opts, html_opts))
        .to eq [[['not-a-known-discipline', 'not-a-known-discipline']], { class: 'moomin force-select' }]
    end

    it "leaves the options untouched for a known term" do
      expect(described_class.include_current_value("Computing and Information - Computer Science", :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end

    it "leaves the options untouched when the value is blank" do
      expect(described_class.include_current_value("", :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end
  end
end
