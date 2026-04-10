# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Transactions::Steps::SaveCollectionThumbnail do
  subject(:step) { described_class.new }

  let(:collection_resource) { FactoryBot.valkyrie_create(:hyrax_collection) }

  context 'update the thumbnail' do
    let(:uploaded) { FactoryBot.create(:uploaded_file) }

    before do
      branding_path = Hyrax.config.branding_path
      FileUtils.rm_f(branding_path) if File.symlink?(branding_path)
      FileUtils.mkdir_p(branding_path)
    end

    it 'successfully updates the thumbnail' do
      expect(step.call(collection_resource, update_thumbnail_file_ids: [uploaded.id.to_s], thumbnail_unchanged_indicator: nil)).to be_success

      expect(CollectionBrandingInfo
               .where(collection_id: collection_resource.id.to_s, role: "thumbnail")
               .where("local_path LIKE '%#{uploaded.file.filename}'"))
        .to exist
    end
  end

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
        CollectionBrandingInfo.create!(
          collection_id: collection_resource.id.to_s,
          role: 'thumbnail',
          local_path: 'thumbnail/thumbnail.png',
          alt_text: ''
        )
      end

      it 'removes the thumbnail when thumbnail_unchanged is omitted (no hidden field) and publishes the event' do
        expect(Hyrax.publisher).to receive(:publish)
          .with('collection.metadata.updated', collection: collection_resource, user: nil)

        expect do
          step.call(collection_resource,
                    update_thumbnail_file_ids: nil,
                    thumbnail_unchanged_indicator: nil,
                    alttext_values: nil)
        end.to change { CollectionBrandingInfo.where(collection_id: collection_resource.id.to_s, role: 'thumbnail').count }
          .from(1).to(0)
      end
    end

    context 'when only updating alt text' do
      let!(:branding_info) do
        CollectionBrandingInfo.create!(
          collection_id: collection_resource.id.to_s,
          role: 'thumbnail',
          local_path: 'thumbnail/thumbnail.png',
          alt_text: 'old alt text'
        )
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

    context 'when uploaded thumbnail branding should be preserved' do
      let!(:branding_info) do
        CollectionBrandingInfo.create!(
          collection_id: collection_resource.id.to_s,
          role: 'thumbnail',
          local_path: 'thumbnail/thumbnail.png',
          alt_text: 'important alt text'
        )
      end

      it 'does not delete thumbnail row when thumbnail_unchanged_indicator is true and alttext_values is nil' do
        allow(Hyrax.publisher).to receive(:publish)

        expect do
          step.call(collection_resource,
                    update_thumbnail_file_ids: nil,
                    thumbnail_unchanged_indicator: 'true',
                    alttext_values: nil)
        end.not_to(change { CollectionBrandingInfo.where(collection_id: collection_resource.id.to_s, role: 'thumbnail').count })

        expect(branding_info.reload.alt_text).to eq('important alt text')
      end

      it 'does not clear alt text when thumbnail_unchanged_indicator is true and alttext_values is [""]' do
        allow(Hyrax.publisher).to receive(:publish)

        step.call(collection_resource,
                  update_thumbnail_file_ids: nil,
                  thumbnail_unchanged_indicator: 'true',
                  alttext_values: [''])

        expect(branding_info.reload.alt_text).to eq('important alt text')
      end
    end
  end
end
