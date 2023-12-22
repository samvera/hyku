# frozen_string_literal: true

RSpec.describe Hyrax::WorkThumbnailPathService, type: :decorator do
  describe '.default_image' do
    context 'when the site has a default work image' do
      let(:image) { '/assets/site_default_work_image.png' }

      it 'returns the default image from the site' do
        allow_any_instance_of(Hyrax::AvatarUploader).to receive(:url).and_return(image)

        expect(described_class.default_image).to eq(image)
      end
    end

    context 'when the site does not have a default work image' do
      it 'returns the default image from Hyrax' do
        expect(described_class.default_image).to eq(ActionController::Base.helpers.image_path('work.png'))
      end
    end
  end
end
