# frozen_string_literal: true

RSpec.describe HyraxHelper, type: :helper do
  describe "#banner_image" do
    context "with uploaded banner image" do
      before do
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(banner_image: f)
      end

      it "returns the uploaded banner image" do
        expect(helper.banner_image).to eq(Site.instance.banner_image.url)
      end
    end

    context "without uploaded banner image" do
      it "returns the configured Hyrax banner image" do
        expect(helper.banner_image).to eq(Hyrax.config.banner_image)
      end
    end
  end

  describe "#directory_image" do
    context "with uploaded directory image" do
      before do
        f = fixture_file_upload('/images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(directory_image: f)
      end

      it "returns the uploaded directory image" do
        expect(helper.directory_image).to eq(Site.instance.directory_image.url)
      end
    end

    context "without uploaded directory image" do
      it "returns false" do
        expect(helper.directory_image).to eq(false)
      end
    end
  end

  describe "#block_for" do
    let(:key_name) { 'some_key' }

    context "when ContentBlock is found" do
      let(:content_block) { FactoryBot.create(:content_block, name: key_name, value: a_value) }
      let(:a_value) { 'some returned text' }

      before do
        content_block
      end
      it "returns text" do
        expect(helper.block_for(name: key_name)).to eq(a_value)
      end
    end

    context "when ContentBlock is not found" do
      let(:a_value) { nil }

      it "returns false" do
        expect(helper.block_for(name: key_name)).to be false
      end
    end
  end
end
