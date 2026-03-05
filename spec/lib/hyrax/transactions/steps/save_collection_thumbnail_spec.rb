# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Transactions::Steps::SaveCollectionThumbnail do
  subject(:step) { described_class.new }

  let(:collection_resource) { FactoryBot.valkyrie_create(:hyrax_collection) }

  describe '#call' do
    it 'returns Success with the collection resource' do
      result = step.call(collection_resource, update_thumbnail_file_ids: nil, alttext_values: nil)
      expect(result).to be_success
      expect(result.value!).to eq(collection_resource)
    end

    it 'publishes collection.metadata.updated to trigger reindexing' do
      expect(Hyrax.publisher).to receive(:publish)
        .with('collection.metadata.updated', collection: collection_resource, user: nil)

      step.call(collection_resource, update_thumbnail_file_ids: nil, alttext_values: nil)
    end

    context 'when removing a thumbnail' do
      let!(:branding_info) do
        FactoryBot.create(:collection_branding_info,
                          collection_id: collection_resource.id.to_s,
                          role: 'thumbnail')
      end

      it 'removes the thumbnail and publishes the event' do
        expect(Hyrax.publisher).to receive(:publish)
          .with('collection.metadata.updated', collection: collection_resource, user: nil)

        expect { step.call(collection_resource, update_thumbnail_file_ids: nil, alttext_values: nil) }
          .to change { CollectionBrandingInfo.where(collection_id: collection_resource.id.to_s, role: 'thumbnail').count }
          .from(1).to(0)
      end
    end

    context 'when only updating alt text' do
      let!(:branding_info) do
        FactoryBot.create(:collection_branding_info,
                          collection_id: collection_resource.id.to_s,
                          role: 'thumbnail',
                          alt_text: 'old alt text')
      end

      it 'updates the alt text and publishes the event' do
        expect(Hyrax.publisher).to receive(:publish)
          .with('collection.metadata.updated', collection: collection_resource, user: nil)

        step.call(collection_resource,
                  update_thumbnail_file_ids: [1],
                  thumbnail_unchanged_indicator: true,
                  alttext_values: ['new alt text'])

        expect(branding_info.reload.alt_text).to eq('new alt text')
      end
    end
  end
end
