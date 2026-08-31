# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'heritage_show theme', type: :request, singletenant: true, clean_repo: true do
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

  before do
    Hyrax::Group.create(name: 'admin')
    sign_in admin
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('heritage_show')
  end

  it 'renders the theme with files and child works in separate rail panels' do
    get "/concern/generic_works/#{parent.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('hrt-show')
    expect(response.body).to include('The Harbor')

    doc = Nokogiri::HTML(response.body)
    files_panel = doc.at_css('#hrt-files').text
    children_panel = doc.at_css('#hrt-children').text

    expect(files_panel).to include('harbor-0001.jpg')
    expect(files_panel).not_to include('Detail scan, piers and schooner')
    expect(children_panel).to include('Detail scan, piers and schooner')
    expect(children_panel).not_to include('harbor-0001.jpg')
  end

  it 'lists what the work belongs to in the rail rather than the metadata table' do
    collection = indexed_with_visibility(Hyrax::PcdmCollection.new(title: ['Photograph Collections']), 'open')
    filed = indexed_with_visibility(
      GenericWorkResource.new(title: ['Filed away'], member_of_collection_ids: [collection.id]), 'open'
    )

    get "/concern/generic_works/#{filed.id}"

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('.hrt-part-of').text).to include('Photograph Collections')
    expect(doc.at_css('.hrt-meta')&.text.to_s).not_to include('Photograph Collections')
  end

  it 'gives an editor the kebab menu with the full action list' do
    get "/concern/generic_works/#{parent.id}"

    menu = Nokogiri::HTML(response.body).at_css('#hrt-files .hrt-file-menu')
    expect(menu).to be_present
    expect(menu.at_css('.hrt-file-kebab .fa-ellipsis-h')).to be_present
    expect(menu.css('.dropdown-item').map { |li| li.text.squish }).to include('Edit', 'Versions', 'Delete')
  end

  it 'offers the citation styles inline with a copy control and an EndNote export' do
    cited = indexed(GenericWorkResource.new(title: ['The Harbor'], creator: ['Detroit Publishing Co.']))

    get "/concern/generic_works/#{cited.id}"

    card = Nokogiri::HTML(response.body).at_css('.hrt-cite')
    expect(card.css('.hrt-cite-picker option').map { |o| o['value'] }).to eq(%w[apa mla chicago])
    expect(card.css('[data-citation-text]').size).to eq(3)
    expect(card.css('[data-citation-text]:not([hidden])').size).to eq(1)
    expect(card.at_css('[data-citation-copy]')).to be_present
    expect(card.at_css('.hrt-cite-export')['href']).to include('endnote')
  end

  it 'keeps the export when a work has no author to build a citation from' do
    get "/concern/generic_works/#{parent.id}"

    card = Nokogiri::HTML(response.body).at_css('.hrt-cite')
    expect(card.at_css('.hrt-cite-picker')).to be_nil
    expect(card.at_css('.hrt-cite-export')['href']).to include('endnote')
  end

  it 'shows the editor controls above the title' do
    get "/concern/generic_works/#{parent.id}"

    expect(Nokogiri::HTML(response.body).at_css('.hrt-show-actions')).to be_present
  end

  context 'as a visitor' do
    let(:public_parent) do
      indexed_with_visibility(GenericWorkResource.new(title: ['Public harbor'], member_ids: [file_set.id]), 'open')
    end

    before { sign_out admin }

    it 'offers a download glyph instead of the editor menu' do
      get "/concern/generic_works/#{public_parent.id}"

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('#hrt-files .hrt-file-download .fa-download')).to be_present
      expect(doc.at_css('#hrt-files .hrt-file-kebab')).to be_nil
      expect(doc.css('.show-actions a.btn:not(.collapse), .show-actions button.btn:not(.collapse)')).to be_empty
    end
  end

  it 'omits a rail panel when the work has no members of that kind' do
    childless = indexed(GenericWorkResource.new(title: ['Childless record'], member_ids: [file_set.id]))

    get "/concern/generic_works/#{childless.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="hrt-files"')
    expect(response.body).not_to include('id="hrt-children"')
  end

  it 'paginates a rail panel at ten entries with a page link' do
    children = Array.new(12) { |i| indexed(GenericWorkResource.new(title: ["Child #{format('%02d', i)}"])) }
    parent = indexed(GenericWorkResource.new(title: ['Big record'], member_ids: children.map(&:id)))

    get "/concern/generic_works/#{parent.id}"

    panel = Nokogiri::HTML(response.body).at_css('#hrt-children')
    expect(panel.css('.hrt-panel-row').size).to eq(10)
    expect(panel.at_css('.hrt-panel-pager .pagination')).to be_present
    expect(panel.at_css('a[href*="items_page=2"]')).to be_present

    get "/concern/generic_works/#{parent.id}?items_page=2"

    panel = Nokogiri::HTML(response.body).at_css('#hrt-children')
    expect(panel.css('.hrt-panel-row').size).to eq(2)
  end

  it 'hides an unreadable child work from the rail' do
    restricted = indexed_with_visibility(GenericWorkResource.new(title: ['Private Child']), 'restricted')
    readable = indexed_with_visibility(GenericWorkResource.new(title: ['Readable Child']), 'open')
    parent = indexed_with_visibility(
      GenericWorkResource.new(title: ['Mixed access record'], member_ids: [restricted.id, readable.id]), 'open'
    )
    sign_in FactoryBot.create(:user)

    get "/concern/generic_works/#{parent.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Readable Child')
    expect(response.body).not_to include('Private Child')
  end
end
