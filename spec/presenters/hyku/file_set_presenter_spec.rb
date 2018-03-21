require 'iiif_manifest'
RSpec.describe Hyku::FileSetPresenter do
  let(:file_set) { FactoryGirl.create(:file_set) }
  let(:solr_document) { SolrDocument.new(file_set.to_solr) }
  let(:request) { double(base_url: 'http://test.host') }
  let(:presenter) { described_class.new(solr_document, nil, request) }
  let(:id) { CGI.escape(file_set.original_file.id) }

  describe "display_image" do
    context "when the file is not an image" do
      subject { presenter.display_image }

      before do
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            fixture_file('csv/sample.csv'), :original_file)
      end
      it { is_expected.to be_nil }
    end
    context "when the file is an image" do
      subject { presenter.display_image }

      before do
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            fixture_file('images/world.png'), :original_file)
      end
      it "creates a display image" do
        expect(subject).to be_instance_of IIIFManifest::DisplayImage
        expect(subject.url).to eq "http://test.host/images/#{id}/full/600,/0/default.jpg"
      end
    end
  end

  describe "iiif_endpoint" do
    subject { presenter.send(:iiif_endpoint, file_set.original_file) }

    before do
      Hydra::Works::AddFileToFileSet.call(file_set,
                                          fixture_file('images/world.png'), :original_file)
    end
    it 'returns the url' do
      expect(subject.url).to eq "http://test.host/images/#{id}"
    end
  end
end
