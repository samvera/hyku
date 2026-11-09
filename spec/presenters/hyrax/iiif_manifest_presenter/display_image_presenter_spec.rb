# frozen_string_literal: true

RSpec.describe Hyrax::IiifManifestPresenter::DisplayImagePresenter do
  let(:presenter) { described_class.new(work) }
  let(:work) { double(GenericWork) }

  it "includes Hyrax::DisplaysContent" do
    expect(described_class.include?(Hyrax::DisplaysContent)).to be true
  end

  it "includes Hyku::DisplaysItemMetadata" do
    expect(described_class.include?(Hyku::DisplaysItemMetadata)).to be true
  end

  describe "#file_set?" do
    before do
      allow(work).to receive(:file_set?).and_return(true)
      allow(work).to receive_messages(image?: false, audio?: false, video?: false, pdf?: true)
    end

    context "when Flipflop.iiif_pdf? is enabled" do
      before { allow(Flipflop).to receive(:iiif_pdf?).and_return(true) }

      it { expect(presenter.file_set?).to be true }
    end

    context "when Flipflop.iiif_pdf? is disabled" do
      before { allow(Flipflop).to receive(:iiif_pdf?).and_return(false) }

      it { expect(presenter.file_set?).to be false }
    end
  end

  describe '#item_metadata' do
    it 'is nil when the presenter was never tagged' do
      expect(presenter.item_metadata).to be_nil
    end

    it 'is nil with a v3 factory when the presenter was never tagged' do
      allow(Hyrax.config).to receive(:iiif_manifest_factory).and_return(::IIIFManifest::V3::ManifestFactory)

      expect(presenter.item_metadata).to be_nil
    end

    it 'wraps plain strings into V3 language maps' do
      allow(Hyrax.config).to receive(:iiif_manifest_factory).and_return(::IIIFManifest::V3::ManifestFactory)
      presenter.item_metadata = [{ 'label' => 'Creator', 'value' => ['Bob'] }]

      expect(presenter.item_metadata).to eq [
        { 'label' => { 'none' => ['Creator'] }, 'value' => { 'none' => ['Bob'] } }
      ]
    end

    it 'passes through already-wrapped V3 language maps' do
      allow(Hyrax.config).to receive(:iiif_manifest_factory).and_return(::IIIFManifest::V3::ManifestFactory)
      presenter.item_metadata = [{ 'label' => { 'en' => ['Creator'] }, 'value' => { 'none' => ['Bob'] } }]

      expect(presenter.item_metadata).to eq [
        { 'label' => { 'en' => ['Creator'] }, 'value' => { 'none' => ['Bob'] } }
      ]
    end
  end
end
