# frozen_string_literal: true

RSpec.describe Hyrax::FeaturedCollectionListsController, type: :controller do
  describe "#create" do
    before do
      allow(controller).to receive(:authorize!).with(:update, FeaturedCollection)
    end

    let(:feature1) { create(:featured_collection) }
    let(:feature2) { create(:featured_collection) }

    it "is successful" do
      post :create, params: {
        format: :json,
        featured_collection_list: {
          featured_collections_attributes: [{ id: feature1.id, order: "2" }, { id: feature2.id, order: "1" }]
        }
      }
      expect(feature1.reload.order).to eq 2
    end
  end
end
