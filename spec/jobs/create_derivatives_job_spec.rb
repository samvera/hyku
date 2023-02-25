# frozen_string_literal: true

RSpec.describe CreateDerivativesJob do
  let(:parent) { create(:generic_work) }
  let(:file_set) { create(:file_set) }
  let(:file) do
    Hydra::PCDM::File.new do |f|
      f.content = content
      f.original_name = original_name
      f.mime_type = mime_type
    end
  end

  before do
    allow(file_set).to receive(:parent_works).and_return([parent])
    file_set.original_file = file
    file_set.save!
  end

  after { described_class.perform_now(file_set, file.id) }

  context "with a pdf file" do
    let(:content) { File.open(File.join(fixture_path, "hyrax/hyrax_test4.pdf")) }
    let(:original_name) { 'hyrax_text4.pdf' }
    let(:mime_type) { 'application/pdf' }

    it "has a bigger thumbnail size than Hyrax" do
      expect(Hydra::Derivatives::PdfDerivatives).to receive(:create)
        .with(/hyrax_text4\.pdf/, outputs: [{ label: :thumbnail,
                                              format: 'jpg',
                                              size: '676x986',
                                              url: String,
                                              layer: 0 }])
    end

    it "runs a full text extract" do
      expect(Hydra::Derivatives::FullTextExtract).to receive(:create)
        .with(/hyrax_text4\.pdf/, outputs: [{ url: RDF::URI, container: "extracted_text" }])
    end
  end

  context "with a doc file" do
    let(:content) { File.open(File.join(fixture_path, "hyrax/test.docx")) }
    let(:original_name) { 'test.docx' }
    let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }

    it "has a bigger thumbnail size than Hyrax" do
      expect(Hydra::Derivatives::DocumentDerivatives).to receive(:create)
        .with(/test\.docx/, outputs: [{ label: :thumbnail,
                                        format: 'jpg',
                                        size: '600x450>',
                                        url: String,
                                        layer: 0 }])
    end

    it "runs a full text extract" do
      expect(Hydra::Derivatives::FullTextExtract).to receive(:create)
        .with(/test\.docx/, outputs: [{ url: RDF::URI, container: "extracted_text" }])
    end
  end

  context "with an image file" do
    let(:content) { File.open(File.join(fixture_path, "hyrax/image.jp2")) }
    let(:original_name) { 'image.jp2' }
    let(:mime_type) { 'image/jp2' }

    it "has a bigger thumbnail size than Hyrax" do
      expect(Hydra::Derivatives::ImageDerivatives).to receive(:create)
        .with(/image\.jp2/, outputs: [{ label: :thumbnail,
                                        format: 'jpg',
                                        size: '600x450>',
                                        url: String,
                                        layer: 0 }])
    end
  end
end
