# frozen_string_literal: true
require 'rails_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SaveCollectionThumbnail do
  subject(:step)   { described_class.new }
  let(:collection) do
    FactoryBot.valkyrie_create(:hyrax_collection,
                               title: "My Resource")
  end

  context 'update the thumbnail' do
    let(:uploaded) { FactoryBot.create(:uploaded_file) }

    it 'successfully updates the thumbnail' do
      expect(step.call(collection, update_thumbnail_file_ids: [uploaded.id.to_s], thumbnail_unchanged_indicator: nil)).to be_success

      expect(CollectionBrandingInfo
               .where(collection_id: collection.id.to_s, role: "thumbnail")
               .where("local_path LIKE '%#{uploaded.file.filename}'"))
        .to exist
    end
  end
end
