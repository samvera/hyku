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
end
