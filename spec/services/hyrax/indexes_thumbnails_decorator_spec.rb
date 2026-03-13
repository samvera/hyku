# frozen_string_literal: true

RSpec.describe Hyrax::IndexesThumbnails, type: :decorator do
  describe '#thumbnail_path' do
    context 'when the object is a Collection' do
      let(:object) { FactoryBot.build(:collection, id: '123') }

      it 'calls the UploadedCollectionThumbnailPathService' do
        allow(UploadedCollectionThumbnailPathService).to receive(:uploaded_thumbnail?).with(object).and_return(true)

        expect(UploadedCollectionThumbnailPathService).to receive(:call).with(object)
        object.update_index
      end
    end

    context 'when the object is not a Collection' do
      let(:object) { FactoryBot.build(:work, id: '123') }

      it 'calls the UploadedCollectionThumbnailPathService' do
        expect(Hyrax::ThumbnailPathService).to receive(:call).with(object)
        object.update_index
      end
    end
  end
end
