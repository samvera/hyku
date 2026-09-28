# frozen_string_literal: true

RSpec.describe Hyrax::MediaViewerService do
  describe "select_options" do
    subject { described_class.select_all_options }

    it "offers every viewer a work can be rendered with" do
      expect(subject).to eq [['Universal Viewer', 'universal_viewer'],
                             ['Clover IIIF', 'clover'],
                             ['Ramp (AV)', 'ramp'],
                             ['PDF.js', 'pdf_js']]
    end
  end

  describe "label" do
    subject { described_class.label("clover") }

    it { is_expected.to eq 'Clover IIIF' }

    context "when the id is not in the authority" do
      it "falls back to the id" do
        expect(described_class.label("not-a-known-viewer")).to eq "not-a-known-viewer"
      end
    end
  end

  describe "active?" do
    it "is true for a known term" do
      expect(described_class.active?("ramp")).to be true
    end

    it "is false for an id not in the authority" do
      expect(described_class.active?("not-a-known-viewer")).to be false
    end
  end

  describe "term ids" do
    it "matches the partial names and asset directories IiifHelper routes to" do
      expect(described_class.select_all_options.map(&:last))
        .to eq %w[universal_viewer clover ramp pdf_js]
    end
  end
end
