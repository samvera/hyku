# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HyraxListener do
  let(:instance) { HyraxListener.new }
  let(:collection) { FactoryBot.build(:hyku_collection) }
  let(:event) { Dry::Events::Event.new(event_type, { collection: }) }

  describe "on_collection_deleted" do
    let(:event_type) { :on_collection_deleted }

    it 'destroys the featured collection instance' do
      expect(FeaturedCollection).to receive(:destroy_for).with(collection:)

      instance.on_collection_metadata_updated(event)
    end
  end

  describe "on_collection_metadata_updated" do
    let(:event_type) { :on_collection_metadata_updated }

    context 'when the collection is private' do
      it 'destroys the featured collection instance' do
        expect(collection).to receive(:private?).and_return(true)
        expect(FeaturedCollection).to receive(:destroy_for).with(collection:)

        instance.on_collection_metadata_updated(event)
      end
    end

    context 'when the resource is not private' do
      it "does not destroy the featured collection" do
        expect(collection).to receive(:private?).and_return(false)
        expect(FeaturedCollection).not_to receive(:destroy_for)

        instance.on_collection_metadata_updated(event)
      end
    end
  end

  describe "on_object_deleted" do
    let(:event) { Dry::Events::Event.new(:on_object_deleted, { object: collection }) }
    let(:collection) { FactoryBot.build(:hyku_collection, id: 'deleted-collection') }

    before do
      FeaturedCollection.create!(collection_id: 'deleted-collection')
      FeaturedCollection.create!(collection_id: 'other-collection')
    end

    it 'destroys only the deleted collection\'s featured collection' do
      instance.on_object_deleted(event)

      expect(FeaturedCollection.pluck(:collection_id)).to eq ['other-collection']
    end

    it 'reads the id when the event carries no object' do
      instance.on_object_deleted(Dry::Events::Event.new(:on_object_deleted, { id: 'deleted-collection' }))

      expect(FeaturedCollection.pluck(:collection_id)).to eq ['other-collection']
    end
  end
end
