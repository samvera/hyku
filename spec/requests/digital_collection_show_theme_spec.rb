# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'digital_collection_show theme', type: :request, singletenant: true, clean_repo: true do
  include Devise::Test::IntegrationHelpers

  let(:admin) { FactoryBot.create(:admin) }
  let(:file_set) { valkyrie_create(:hyrax_file_set, title: ['harbor-0001.jpg'], visibility_setting: 'open') }
  let(:child_work) { indexed(GenericWorkResource.new(title: ['Detail scan, piers and schooner'])) }
  let(:parent) { indexed(GenericWorkResource.new(title: ['The Harbor'], member_ids: [file_set.id, child_work.id])) }

  def indexed(resource)
    saved = Hyrax.persister.save(resource:)
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_with_visibility(resource, visibility)
    saved = Hyrax.persister.save(resource:)
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_collection(title, visibility = 'open')
    indexed_with_visibility(
      Hyrax::PcdmCollection.new(
        title: [title],
        collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s
      ),
      visibility
    )
  end

  before do
    Hyrax::Group.create(name: 'admin')
    sign_in admin
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('digital_collection_show')
  end

  describe 'the work page' do
    it 'renders the theme shell with the title, a type chip and the rail' do
      get "/concern/generic_works/#{parent.id}"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.dc-show h1.dc-show-title').text).to include('The Harbor')
      expect(doc.at_css('.dc-show-badge .dc-chip')).to be_present
      expect(doc.at_css('aside.dc-show-rail')).to be_present
      expect(doc.at_css('.dc-meta h2#dc-meta-label')).to be_present
    end

    it 'renders a work with no creation date, and puts the author and date in the byline when present' do
      undated = indexed(GenericWorkResource.new(title: ['Undated record']))
      dated = indexed(GenericWorkResource.new(title: ['Dated record'], creator: ['Detroit Publishing Co.'], date_created: ['1905']))

      get "/concern/generic_works/#{undated.id}"
      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css('.dc-show-byline')).to be_nil

      get "/concern/generic_works/#{dated.id}"
      expect(Nokogiri::HTML(response.body).at_css('.dc-show-byline').text).to include('Detroit Publishing Co.', '1905')
    end

    it 'lists files and child works together in the items panel' do
      get "/concern/generic_works/#{parent.id}"

      panel = Nokogiri::HTML(response.body).at_css('section#dc-items')
      expect(panel.at_css('h2.dc-panel-label#dc-items-label')).to be_present
      expect(panel.css('.dc-item-row').size).to eq(2)
      expect(panel.text).to include('harbor-0001.jpg', 'Detail scan, piers and schooner')
      expect(panel.at_css('.dc-panel-count').text.strip).to eq('2')
    end

    it 'shows an editor the empty items panel on a work with no members' do
      empty = indexed(GenericWorkResource.new(title: ['Empty record']))

      get "/concern/generic_works/#{empty.id}"

      panel = Nokogiri::HTML(response.body).at_css('section#dc-items')
      expect(panel.at_css('.dc-panel-empty')).to be_present
      expect(panel.at_css('.dc-item-list')).to be_nil
    end

    it 'shows the viewer placeholder when there is nothing to view' do
      empty = indexed(GenericWorkResource.new(title: ['Empty record']))

      get "/concern/generic_works/#{empty.id}"

      expect(Nokogiri::HTML(response.body).at_css('.dc-viewer.dc-viewer-empty .dc-viewer-placeholder')).to be_present
    end

    it 'lists what the work belongs to in the part-of panel' do
      collection = indexed_collection('Photograph Collections')
      filed = indexed_with_visibility(
        GenericWorkResource.new(title: ['Filed away'], member_of_collection_ids: [collection.id]), 'open'
      )

      get "/concern/generic_works/#{filed.id}"

      panel = Nokogiri::HTML(response.body).at_css('section.dc-part-of')
      expect(panel.at_css('h2.dc-panel-label#dc-part-of-label')).to be_present
      expect(panel.text).to include('Photograph Collections')
    end

    it 'leaves the part-of panel out when the work belongs to nothing' do
      get "/concern/generic_works/#{parent.id}"

      expect(Nokogiri::HTML(response.body).at_css('section.dc-part-of')).to be_nil
    end

    it 'offers the citation styles with a copy control and an EndNote export' do
      cited = indexed(GenericWorkResource.new(title: ['The Harbor'], creator: ['Detroit Publishing Co.']))

      get "/concern/generic_works/#{cited.id}"

      card = Nokogiri::HTML(response.body).at_css('section.dc-cite')
      expect(card.css('.dc-cite-picker option').map { |o| o['value'] }).to eq(%w[apa mla chicago])
      expect(card.css('[data-citation-text]').size).to eq(3)
      expect(card.css('[data-citation-text]:not([hidden])').size).to eq(1)
      expect(card.at_css('button.dc-cite-copy[data-citation-copy]')).to be_present
      expect(card.at_css('.dc-cite-export')['href']).to include('endnote')
    end

    it 'keeps the export when a work has no author to build a citation from' do
      get "/concern/generic_works/#{parent.id}"

      card = Nokogiri::HTML(response.body).at_css('section.dc-cite')
      expect(card.at_css('.dc-cite-picker')).to be_nil
      expect(card.at_css('.dc-cite-export')['href']).to include('endnote')
    end

    it 'shows the editor controls above the title' do
      get "/concern/generic_works/#{parent.id}"

      expect(Nokogiri::HTML(response.body).at_css('.dc-show-actions .show-actions')).to be_present
    end

    it 'renders the digital collection masthead and searchbar' do
      get "/concern/generic_works/#{parent.id}"

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('body')['class']).to include('digital_collection_show')
      expect(doc.at_css('.dc-searchbar-show form')).to be_present
    end

    context 'as a visitor' do
      let(:public_parent) do
        indexed_with_visibility(GenericWorkResource.new(title: ['Public harbor'], member_ids: [file_set.id]), 'open')
      end

      before { sign_out admin }

      it 'hides the editor controls and the empty-panel hint' do
        empty = indexed_with_visibility(GenericWorkResource.new(title: ['Public empty']), 'open')

        get "/concern/generic_works/#{public_parent.id}"
        doc = Nokogiri::HTML(response.body)
        expect(doc.css('.show-actions a.btn:not(.collapse), .show-actions button.btn:not(.collapse)')).to be_empty

        get "/concern/generic_works/#{empty.id}"
        expect(Nokogiri::HTML(response.body).at_css('section#dc-items')).to be_nil
      end
    end

    it 'hides an unreadable child work from the items panel' do
      restricted = indexed_with_visibility(GenericWorkResource.new(title: ['Private Child']), 'restricted')
      readable = indexed_with_visibility(GenericWorkResource.new(title: ['Readable Child']), 'open')
      mixed = indexed_with_visibility(
        GenericWorkResource.new(title: ['Mixed access record'], member_ids: [restricted.id, readable.id]), 'open'
      )
      sign_in FactoryBot.create(:user)

      get "/concern/generic_works/#{mixed.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Readable Child')
      expect(response.body).not_to include('Private Child')
    end
  end

  describe 'the collection page' do
    it 'renders the banner plate with the title and item count' do
      collection = indexed_collection('Harbor Photographs')

      get "/collections/#{collection.id}"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.hyc-banner-glass h1.hyc-title').text).to include('Harbor Photographs')
      expect(doc.at_css('.hyc-item-count')).to be_present
    end

    it 'falls back to the no-image banner when no banner is uploaded' do
      collection = indexed_collection('Harbor Photographs')

      get "/collections/#{collection.id}"

      expect(Nokogiri::HTML(response.body).at_css('.hyc-banner.hyc-banner--no-image')).to be_present
    end
  end
end
