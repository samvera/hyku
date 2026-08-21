# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'practice research home theme', type: :request, singletenant: true, clean_repo: true do
  let!(:collection) do
    saved = Hyrax.persister.save(resource: Hyrax::PcdmCollection.new(title: ['Studio Practice']))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  before do
    [['Site sketchbook', 'open'], ['Unreleased maquette', 'restricted']].each do |title, visibility|
      saved = Hyrax.persister.save(
        resource: GenericWorkResource.new(title: [title], member_of_collection_ids: [collection.id])
      )
      Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
      saved.permission_manager.acl.save
      Hyrax.index_adapter.save(resource: saved)
    end
    FeaturedCollection.create!(collection_id: collection.id.to_s, order: 0)
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('practice_research')
  end

  it 'counts only the collection members a visitor may see' do
    get root_path

    card = Nokogiri::HTML(response.body).at_css('.pr-portfolio')
    expect(card.text).to include('Studio Practice')
    expect(card.at_css('.pr-eyebrow-count').text.strip).to eq('1 work')
  end
end
