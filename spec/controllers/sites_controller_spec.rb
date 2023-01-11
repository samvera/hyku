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

    context 'selecting a theme' do
      it 'sets the home, search, and show themes' do
        expect(Site.instance.home_theme).to be nil
        post :update, params: {
          site: { home_theme: 'home page theme', search_theme: 'gallery', show_theme: 'show page theme' }
        }
        expect(Site.instance.home_theme).to eq 'home page theme'
        expect(Site.instance.search_theme).to eq 'gallery'
        expect(Site.instance.show_theme).to eq 'show page theme'
        expect(flash[:notice]).to include('The appearance was successfully updated')
      end
    end

    context "site with existing banner image" do
      before do
        expect(Hyrax::AvatarUploader)
          .to receive(:storage)
          .and_return(CarrierWave::Storage::File)
          .at_least(3).times
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(banner_image: f)
        ContentBlock.find_or_create_by(name: 'banner_image_text').update!(value: 'Sample text')
      end

      it "#update with remove_banner_image deletes a banner image" do
        expect(Site.instance.banner_image?).to be true
        expect(ContentBlock.find_by(name: 'banner_image_text')).not_to be nil
        post :update, params: { id: Site.instance.id, remove_banner_image: 'Remove banner image' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include("The appearance was successfully updated")
        expect(Site.instance.banner_image?).to be false
        expect(ContentBlock.find_by(name: 'banner_image_text')).to be nil
      end
    end

    context "site with existing favicon" do
      before do
        FaviconUploader.enable_processing = false
        file = fixture_file_upload('/images/favicon.png', 'image/png')
        Site.instance.update(favicon: file)
        FaviconUploader.enable_processing = true
      end

      it "#update with remove_favicon deletes a favicon" do
        expect(Site.instance.favicon?).to be true
        post :update, params: { id: Site.instance.id, remove_favicon: 'Remove favicon' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include("The appearance was successfully updated")
        expect(Site.instance.favicon?).to be false
      end
    end

    context "site with existing directory image" do
      before do
        expect(Hyrax::AvatarUploader).to receive(:storage).and_return(CarrierWave::Storage::File).at_least(3).times
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(directory_image: f)
        ContentBlock.find_or_create_by(name: 'directory_image_text').update!(value: 'Sample text')
      end

      it "#update with remove_directory_image deletes a directory image" do
        expect(Site.instance.directory_image?).to be true
        expect(ContentBlock.find_by(name: 'directory_image_text')).not_to be nil
        post :update, params: { id: Site.instance.id, remove_directory_image: 'Remove directory image' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include("The appearance was successfully updated")
        expect(Site.instance.directory_image?).to be false
        expect(ContentBlock.find_by(name: 'directory_image_text')).to be nil
      end

      context 'when update fails' do
        let(:site) { Site.instance }

        before do
          allow(Site).to receive(:instance).and_return(site)
          allow(site).to receive(:update).and_return(false)
        end

        it "#update with remove_directory_image sets error flash" do
          expect(Site.instance.directory_image?).to be true
          expect(ContentBlock.find_by(name: 'directory_image_text')).not_to be nil
          post :update, params: { id: Site.instance.id, remove_directory_image: 'Remove directory image' }
          expect(response).to redirect_to('/admin/appearance?locale=en')
          expect(flash[:error]).to include("Updating the appearance was unsuccessful")
          expect(Site.instance.directory_image?).to be true
          expect(ContentBlock.find_by(name: 'directory_image_text')).not_to be nil
        end
      end
    end

    context "site with existing logo image and logo text" do
      before do
        expect(Hyrax::AvatarUploader)
          .to receive(:storage)
          .and_return(CarrierWave::Storage::File)
          .at_least(3).times
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(logo_image: f)
        ContentBlock.find_or_create_by(name: 'logo_image_text').update!(value: 'Sample text')
      end

      it "#update with remove_logo_image deletes both image and text" do
        expect(ContentBlock.find_by(name: 'logo_image_text')).not_to be nil
        expect(Site.instance.logo_image?).to be true
        post :update, params: { id: Site.instance.id, remove_logo_image: 'Remove logo image' }
        expect(response).to redirect_to('/admin/appearance?locale=en')
        expect(flash[:notice]).to include("The appearance was successfully updated")
        expect(Site.instance.logo_image?).to be false
        expect(ContentBlock.find_by(name: 'logo_image_text')).to be nil
      end
    end
  end
end
