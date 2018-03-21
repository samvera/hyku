RSpec.describe FileSetIndexer do
  describe 'thumbnail_path_service' do
    subject { described_class.thumbnail_path_service }

    it { is_expected.to eq IIIFWorkThumbnailPathService }
  end
end
