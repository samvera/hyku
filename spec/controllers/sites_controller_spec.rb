# frozen_string_literal: true

RSpec.describe SitesController, type: :controller, singletenant: true do
  before { sign_in user }

  context 'with an unprivileged user' do
    let(:user) { create(:user) }

    describe "POST #update" do
      it "denies the request" do
        post :update
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context 'with an administrator' do
    let(:user) { create(:admin) }

    context 'site with existing logo image' do
      before do
        expect(Hyrax::UploadedFileUploader)
          .to receive(:storage)
          .and_return(CarrierWave::Storage::File)
          .at_least(2).times
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(logo_image: f)
      end

      it '#update with remove_logo_image deletes a logo image' do
        expect(Site.instance.logo_image?).to be true
        post :update, params: { id: Site.instance.id, remove_logo_image: 'Remove logo image' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include('The appearance was successfully updated')
        expect(Site.instance.logo_image?).to be false
      end
    end

    context "site with existing banner image" do
      before do
        expect(Hyrax::UploadedFileUploader)
          .to receive(:storage)
          .and_return(CarrierWave::Storage::File)
          .at_least(3).times
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(banner_image: f)
      end

      it "#update with remove_banner_image deletes a banner image" do
        expect(Site.instance.banner_image?).to be true
        post :update, params: { id: Site.instance.id, remove_banner_image: 'Remove banner image' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include("The appearance was successfully updated")
        expect(Site.instance.banner_image?).to be false
      end
    end

    context "site with existing directory image" do
      before do
        expect(Hyrax::AvatarUploader).to receive(:storage).and_return(CarrierWave::Storage::File).at_least(3).times
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(directory_image: f)
      end

      it "#update with remove_directory_image deletes a directory image" do
        expect(Site.instance.directory_image?).to be true
        post :update, params: { id: Site.instance.id, remove_directory_image: 'Remove directory image' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include("The appearance was successfully updated")
        expect(Site.instance.directory_image?).to be false
      end
    end

    context 'site with existing default collection image' do
      before do
        expect(Hyrax::UploadedFileUploader)
          .to receive(:storage)
          .and_return(CarrierWave::Storage::File)
          .at_least(2).times
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(default_collection_image: f)
      end

      it '#update with remove_default_collection_image deletes a default_collection image' do
        expect(Site.instance.default_collection_image?).to be true
        post :update, params: { id: Site.instance.id, remove_default_collection_image: 'Remove default_collection image' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include('The appearance was successfully updated')
        expect(Site.instance.default_collection_image?).to be false
      end

      it 'enqueues two jobs' do
        expect(ReindexCollectionsJob).to receive(:perform_later).once
        expect(ReindexAdminSetsJob).to receive(:perform_later).once

        post :update, params: { id: Site.instance.id, remove_default_collection_image: 'Remove default_collection image' }
      end
    end

    context 'site with existing default work image' do
      before do
        expect(Hyrax::UploadedFileUploader)
          .to receive(:storage)
          .and_return(CarrierWave::Storage::File)
          .at_least(2).times
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(default_work_image: f)
      end

      it '#update with remove_default_work_image deletes a default_work image' do
        expect(Site.instance.default_work_image?).to be true
        post :update, params: { id: Site.instance.id, remove_default_work_image: 'Remove default_work image' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include('The appearance was successfully updated')
        expect(Site.instance.default_work_image?).to be false
      end

      it 'enqueues one jobs' do
        expect(ReindexWorksJob).to receive(:perform_later).once

        post :update, params: { id: Site.instance.id, remove_default_work_image: 'Remove default_work image' }
      end
    end
  end
end
