# frozen_string_literal: true

RSpec.describe Hyrax::IiifManifestPresenter::DisplayImagePresenter do
  let(:presenter) { described_class.new(work) }

  let(:work) { double(GenericWork) }

  # verify the native Hyrax AV concern is mixed in
  it "includes Hyrax::DisplaysContent" do
    expect(described_class.include?(Hyrax::DisplaysContent)).to be true
  end

  describe "#file_set?" do
    before do
      # stubbing this so super returns true
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
end
