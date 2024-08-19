# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Collection do
  let(:user) { create(:user).tap { |u| u.add_role(:admin, Site.instance) } }
  let(:account) { create(:account) }
  let(:collection) { create(:collection, user:) }

  before do
    Site.update(account:)
  end

  it "is a hyrax collection" do
    expect(described_class.ancestors).to include Hyrax::CollectionBehavior
  end

  describe ".indexer" do
    subject { described_class.indexer }

    it { is_expected.to eq CollectionIndexer }
  end

  describe "Featured Collections" do
    before do
      FeaturedCollection.create(collection_id: collection.id)
    end

    describe "#update" do
      context "when collection is public" do
        let(:collection) { create(:public_collection) }

        it "does not remove the collection from featured collections" do
          expect(collection).not_to receive(:remove_featured)
          collection.update(title: ['New collection title'])
        end
      end

      context "when collection is private" do
        let(:collection) { create(:private_collection) }

        it "removes collection from featured collections" do
          expect(collection).to receive(:remove_featured)
          collection.update(title: ['New collection title'])
        end
      end

      context "when collection is changed from public to private" do
        let(:collection) { create(:public_collection) }

        it "removes collection from featured collections" do
          expect(collection).to receive(:remove_featured)
          collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          collection.save!
        end
      end
    end

    describe "#destroy" do
      it 'deletes the featured collection after destroying the collection' do
        expect(collection).to receive(:remove_featured)
        collection.destroy
      end
    end

    describe "#remove_featured" do
      it 'removes collection from featured collections' do
        expect(FeaturedCollection.where(collection_id: collection.id).count).to eq(1)
        collection.remove_featured
        expect(FeaturedCollection.where(collection_id: collection.id).count).to eq(0)
      end
    end
  end
end
