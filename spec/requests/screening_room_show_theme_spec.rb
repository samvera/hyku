# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'screening_room_show theme', type: :request, singletenant: true, clean_repo: true do
  let(:collection) do
    indexed(Hyrax::PcdmCollection.new(title: ['Film and Television']))
  end
  let(:work) do
    indexed(GenericWorkResource.new(title: ['Pilot boats in New York harbor'],
                                    description: ['A New York harbor pilot boat passes close.'],
                                    resource_type: ['Moving image'],
                                    member_of_collection_ids: [collection.id]))
  end

  def indexed(resource)
    saved = Hyrax.persister.save(resource:)
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('screening_room_show')
  end

  it 'offers a visitor no actions but keeps the citation hook citation managers read' do
    get "/concern/generic_works/#{work.id}"

    doc = Nokogiri::HTML(response.body)
    expect(doc.css('.scr-show-actions .show-actions .btn')).to be_empty
    expect(doc.at_css('span.Z3988')['title']).to be_present
  end

  context 'as an editor' do
    include Devise::Test::IntegrationHelpers

    let(:admin) { FactoryBot.create(:admin) }

    before do
      Hyrax::Group.create(name: 'admin')
      sign_in admin
    end

    it 'puts the action row above the viewer' do
      get "/concern/generic_works/#{work.id}"

      doc = Nokogiri::HTML(response.body)
      actions = doc.at_css('.scr-show-actions')
      expect(actions.text).to include('Edit')
      expect(doc.css('.scr-show *').index(actions)).to be < doc.css('.scr-show *').index(doc.at_css('.scr-show-body'))
    end
  end

  it 'opens with the title block over the description' do
    get "/concern/generic_works/#{work.id}"

    expect(response).to have_http_status(:ok)

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('.scr-chip').text.strip).to eq('Moving image')
    expect(doc.at_css('.scr-show-context').text).to include('Film and Television')
    expect(doc.at_css('.scr-show-title').text).to include('Pilot boats in New York harbor')
    expect(doc.at_css('.scr-show-lede').text).to include('pilot boat passes close')
  end

  describe 'the items panel' do
    let(:file_set) do
      indexed(Hyrax::FileSet.new(title: ['reel-001.mp4']))
    end
    let(:child) do
      indexed(GenericWorkResource.new(title: ['Reel 1 transfer']))
    end
    let(:parent) do
      indexed(GenericWorkResource.new(title: ['Parent reel'], member_ids: [file_set.id, child.id]))
    end

    it 'lists files and child works together with their visibility' do
      get "/concern/generic_works/#{parent.id}"

      panel = Nokogiri::HTML(response.body).at_css('#scr-items')
      expect(panel.at_css('.scr-panel-count').text.strip).to eq('2 items')
      expect(panel.css('.scr-panel-name').map { |n| n.text.strip }).to eq(['reel-001.mp4', 'Reel 1 transfer'])
      expect(panel.css('.scr-panel-meta').map { |meta| meta.text.strip })
        .to all(match(/\APublic · \w+ \d{1,2}, \d{4}\z/))
    end

    it 'leaves the panel empty-handed when the work has no members' do
      get "/concern/generic_works/#{work.id}"

      panel = Nokogiri::HTML(response.body).at_css('#scr-items')
      expect(panel.css('.scr-panel-row')).to be_empty
      expect(panel.at_css('.scr-panel-empty')).to be_present
    end
  end

  it 'carries the breadcrumb trail in the search band' do
    get "/concern/generic_works/#{work.id}"

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('.scr-searchbar-show .breadcrumb').text).to include('Pilot boats in New York harbor')
  end

  it 'drops the lede when the work has no description' do
    bare = indexed(GenericWorkResource.new(title: ['Untitled reel']))

    get "/concern/generic_works/#{bare.id}"

    expect(Nokogiri::HTML(response.body).at_css('.scr-show-lede')).to be_nil
  end

  it 'names the collection only when the visitor may read it' do
    hidden = Hyrax.persister.save(resource: Hyrax::PcdmCollection.new(title: ['Restricted Reels']))
    Hyrax::VisibilityWriter.new(resource: hidden).assign_access_for(visibility: 'restricted')
    hidden.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: hidden)
    filed = indexed(GenericWorkResource.new(title: ['Filed away'], member_of_collection_ids: [hidden.id]))

    get "/concern/generic_works/#{filed.id}"

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('.scr-show-context')).to be_nil
    expect(doc.at_css('.scr-show-head').text).not_to include('Restricted Reels')
  end

  context 'on the collection show page' do
    let(:shown) do
      shown = FactoryBot.valkyrie_create(:hyrax_collection, title: ['Film and Television'])
      Hyrax::VisibilityWriter.new(resource: shown).assign_access_for(visibility: 'open')
      shown.permission_manager.acl.save
      Hyrax.index_adapter.save(resource: shown)
      shown
    end

    it 'carries the theme chrome' do
      get "/collections/#{shown.id}"

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.scr-searchbar-show .scr-crumbs')).to be_present
    end

    it 'leaves an unthemed tenant with the default chrome' do
      allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('default_show')

      get "/collections/#{shown.id}"

      expect(Nokogiri::HTML(response.body).at_css('.scr-searchbar-show')).to be_nil
    end

    context 'as an editor' do
      include Devise::Test::IntegrationHelpers

      let(:admin) { FactoryBot.create(:admin) }

      before do
        Hyrax::Group.create(name: 'admin')
        sign_in admin
      end

      it 'skins the action row the theme owns' do
        get "/collections/#{shown.id}"

        expect(Nokogiri::HTML(response.body).css('.show-actions-container .btn')).not_to be_empty
      end
    end
  end

  context 'on the file set show page' do
    let(:file_set) do
      indexed(Hyrax::FileSet.new(title: ['reel-001.mp4']))
    end
    let(:parent) do
      indexed(GenericWorkResource.new(title: ['Parent reel'], member_ids: [file_set.id]))
    end

    it 'carries the theme chrome' do
      get "/concern/parent/#{parent.id}/file_sets/#{file_set.id}"

      expect(Nokogiri::HTML(response.body).at_css('.scr-searchbar-show .scr-crumbs')).to be_present
    end

    context 'as an editor' do
      include Devise::Test::IntegrationHelpers

      let(:admin) { FactoryBot.create(:admin) }

      before do
        Hyrax::Group.create(name: 'admin')
        sign_in admin
      end

      it 'skins the single use link table the theme owns' do
        get "/concern/parent/#{parent.id}/file_sets/#{file_set.id}"

        expect(Nokogiri::HTML(response.body).at_css('table.table.single-use-links')).to be_present
      end
    end
  end
end
