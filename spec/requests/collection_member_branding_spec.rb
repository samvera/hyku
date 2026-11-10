# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Removing a work from a collection on the dashboard', type: :request, singletenant: true, clean: true do
  let(:admin) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.valkyrie_create(:generic_work_resource) }
  let(:collection) { FactoryBot.valkyrie_create(:hyku_collection, members: [work]) }
  let(:branding) { CollectionBrandingInfo.where(collection_id: collection.id.to_s) }

  before do
    %w[banner logo thumbnail].each do |role|
      CollectionBrandingInfo.new(collection_id: collection.id.to_s, filename: "#{role}.png", role:, alt_txt: "#{role} alt")
                            .save("unused", false)
    end
    login_as admin
  end

  it 'keeps the banner, logo and thumbnail' do
    expect do
      put hyrax.dashboard_collection_path(collection), params: { collection: { members: 'remove' }, batch_document_ids: [work.id.to_s] }
    end.not_to(change { branding.pluck(:role).sort })

    expect(response).to redirect_to(hyrax.dashboard_collection_path(collection, locale: 'en'))
    expect(Hyrax.custom_queries.find_members_of(collection:).map(&:id)).not_to include(work.id)
  end

  it 'removes the work even when the collection is missing required metadata' do
    collection.creator = []
    Hyrax.persister.save(resource: collection)

    expect do
      put hyrax.dashboard_collection_path(collection), params: { collection: { members: 'remove' }, batch_document_ids: [work.id.to_s] }
    end.not_to(change { branding.pluck(:role).sort })

    expect(Hyrax.custom_queries.find_members_of(collection:).map(&:id)).not_to include(work.id)
  end

  it 'still saves other collection fields sent with a member change' do
    put hyrax.dashboard_collection_path(collection),
        params: { collection: { members: 'remove', title: ['Renamed'] }, batch_document_ids: [work.id.to_s] }

    expect(Hyrax.query_service.find_by(id: collection.id).title).to eq(['Renamed'])
  end

  it 'keeps branding when the edit form is saved with the unchanged flags (control)' do
    logo_path = branding.find_by(role: 'logo').local_path

    expect do
      put hyrax.dashboard_collection_path(collection),
          params: { collection: { title: ['Renamed'] }, banner_unchanged: 'true', banner_text: ['banner alt'],
                    thumbnail_unchanged: 'true', thumbnail_text: ['thumbnail alt'],
                    logo_files: [logo_path], alttext: ['logo alt'], linkurl: [''] }
    end.not_to(change { branding.pluck(:role).sort })
  end
end
