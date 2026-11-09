# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyku::ListenerSubscription do
  describe '.replace' do
    let(:publisher) { Hyrax::Publisher.send(:new) }
    let(:collection) { FactoryBot.build(:hyku_collection) }

    before { allow(FeaturedCollection).to receive(:destroy_for) }

    def publish_collection_deleted
      publisher.publish('collection.deleted', collection:, id: 'an_id', user: nil)
    end

    it 'delivers each event once when called repeatedly' do
      3.times { described_class.replace(HyraxListener.new, publisher:) }
      publish_collection_deleted

      expect(FeaturedCollection).to have_received(:destroy_for).once
    end

    it 'replaces a listener whose class was unloaded by a code reload' do
      unloaded_class = Class.new do
        def self.name = 'HyraxListener'

        def on_collection_deleted(event)
          FeaturedCollection.destroy_for(collection: event[:collection])
        end
      end
      publisher.subscribe(unloaded_class.new)

      described_class.replace(HyraxListener.new, publisher:)
      publish_collection_deleted

      expect(FeaturedCollection).to have_received(:destroy_for).once
    end
  end
end
