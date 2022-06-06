# frozen_string_literal: true

RSpec.describe Hyrax::FeaturedCollectionsController, type: :controller do
  describe "#create" do
    before do
      sign_in create(:user)
    end

    context "when there are no featured collections" do
      it "creates one" do
        expect(controller).to receive(:authorize!).with(:create, FeaturedCollection).and_return(true)
        expect do
          post :create, params: { id: '1234abcd', format: :json }
        end.to change(FeaturedCollection, :count).by(1)
        expect(response).to be_successful
      end
    end

    context "when there are 6 featured collections" do
      before do
        6.times do |n|
          FeaturedCollection.create(collection_id: n.to_s)
        end
      end
      it "does not create another" do
        expect(controller).to receive(:authorize!).with(:create, FeaturedCollection).and_return(true)
        expect do
          post :create, params: { id: '1234abcd', format: :json }
        end.not_to change(FeaturedCollection, :count)
        expect(response.status).to eq 422
      end
    end
  end

  describe "#destroy" do
    before do
      sign_in create(:user)
    end

    context "when the collection exists" do
      before { create(:featured_collection, collection_id: '1234abcd') }

      it "removes it" do
        expect(controller).to receive(:authorize!).with(:destroy, FeaturedCollection).and_return(true)
        expect do
          delete :destroy, params: { id: '1234abcd', format: :json }
        end.to change(FeaturedCollection, :count).by(-1)
        expect(response.status).to eq 204
      end
    end

    context "when it was already removed" do
      it "doesn't raise an error" do
        expect(controller).to receive(:authorize!).with(:destroy, FeaturedCollection).and_return(true)
        delete :destroy, params: { id: '1234abcd', format: :json }
        expect(response.status).to eq 204
      end
    end
  end
end
