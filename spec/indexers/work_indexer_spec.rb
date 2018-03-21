RSpec.describe WorkIndexer do
  describe 'thumbnail_path_service' do
    subject { described_class.thumbnail_path_service }

    it { is_expected.to eq IIIFWorkThumbnailPathService }
  end

  describe 'rdf_service' do
    subject { indexer.rdf_service }

    let(:work) { instance_double(Image) }
    let(:indexer) { described_class.new(work) }

    it { is_expected.to eq Hyrax::DeepIndexingService }
  end
end
