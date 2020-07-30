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

      context 'when update fails' do
        let(:site) { Site.instance }

        before do
          allow(Site).to receive(:instance).and_return(site)
          allow(site).to receive(:update).and_return(false)
        end

        it "#update with remove_directory_image sets error flash" do
          expect(Site.instance.directory_image?).to be true
          post :update, params: { id: Site.instance.id, remove_directory_image: 'Remove directory image' }
          expect(response).to redirect_to('/admin/appearance?locale=en')
          expect(flash[:error]).to include("Updating the appearance was unsuccessful")
          expect(Site.instance.directory_image?).to be true
        end
      end
    end
  end
end
