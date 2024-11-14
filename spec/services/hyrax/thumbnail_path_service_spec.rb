# frozen_string_literal: true

RSpec.describe Hyrax::ThumbnailPathService, type: :decorator do
  describe '.default_image' do
    context 'when the site has a default image' do
      let(:image) { '/assets/site_default_work_image.png' }

      it 'returns the default image from the site' do
        allow_any_instance_of(Hyrax::AvatarUploader).to receive(:url).and_return(image)

        expect(described_class.default_image).to eq(image)
      end
    end

    context 'when the site does not have a default image' do
      it 'returns the default image from Hyrax' do
        expect(described_class.default_image).to eq(ActionController::Base.helpers.image_path('default.png'))
      end
    end
  end

  describe '.default_collection_image' do
    context 'when the site has a default collection image' do
      let(:collection_image) { '/assets/site_default_collection_image.png' }
      let(:site_instance_double) { instance_double(Site, default_collection_image: double('DefaultCollectionImage', url: collection_image)) }

      before do
        # Stub Site.instance to return our site_instance_double with the expected url
        allow(Site).to receive(:instance).and_return(site_instance_double)
      end

      it 'returns the default collection image from the site' do
        expect(described_class.default_collection_image).to eq(collection_image)
      end
    end

    context 'when the site does not have a default collection image' do
      it 'returns the Hyrax default collection image' do
        expect(described_class.default_collection_image).to eq(ActionController::Base.helpers.image_path('default.png'))
      end
    end
  end
end
