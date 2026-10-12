# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'reference_show theme', type: :request, singletenant: true, clean_repo: true do
  include Devise::Test::IntegrationHelpers

  let(:admin) { FactoryBot.create(:admin) }
  let(:file_set) { valkyrie_create(:hyrax_file_set, title: ['plate-001.tif'], visibility_setting: 'open') }
  let(:child_work) { indexed(GenericWorkResource.new(title: ['Appendix B'], resource_type: ['Text'])) }

  def indexed(resource)
    saved = Hyrax.persister.save(resource:)
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def show_page(work, query = {})
    get "/concern/generic_works/#{work.id}", params: query
    Nokogiri::HTML(response.body)
  end

  before do
    Hyrax::Group.create(name: 'admin')
    sign_in admin
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('reference_show')
  end

  describe 'the tab strip' do
    it 'offers metadata alone, unbadged, for a work with no members' do
      bare = indexed(GenericWorkResource.new(title: ['A lone record']))

      doc = show_page(bare)

      expect(response).to have_http_status(:ok)
      expect(doc.css('.ref-tabs .nav-link').map { |tab| tab.text.strip }).to eq(['Metadata'])
      expect(doc.at_css('.ref-tab-count')).to be_nil
    end

    it 'badges files and child works with their counts and keeps each in its own pane' do
      parent = indexed(
        GenericWorkResource.new(title: ['Primary record'], member_ids: [file_set.id, child_work.id])
      )

      doc = show_page(parent)

      expect(doc.css('.ref-tabs .nav-link').map { |tab| tab.at_css('.ref-tab-count')&.text })
        .to eq([nil, '1', '1'])

      expect(doc.at_css('#ref-pane-files').text).to include('plate-001.tif')
      expect(doc.at_css('#ref-pane-files').text).not_to include('Appendix B')
      expect(doc.at_css('#ref-pane-children').text).to include('Appendix B')
      expect(doc.at_css('#ref-pane-children').text).not_to include('plate-001.tif')
    end

    it 'drops the files tab for a work that holds only child works' do
      parent = indexed(GenericWorkResource.new(title: ['Container'], member_ids: [child_work.id]))

      doc = show_page(parent)

      expect(doc.at_css('#ref-pane-files')).to be_nil
      expect(doc.at_css('#ref-pane-children')).to be_present
    end
  end

  describe 'choosing a pane without javascript' do
    let(:parent) do
      indexed(GenericWorkResource.new(title: ['Primary record'], member_ids: [file_set.id, child_work.id]))
    end

    def active_pane(doc)
      doc.at_css('.ref-panes .tab-pane.active')&.[]('id')
    end

    it 'opens the first pane when the request names none' do
      doc = show_page(parent)

      expect(active_pane(doc)).to eq('ref-pane-metadata')
      expect(doc.at_css('#ref-tab-metadata')['aria-selected']).to eq('true')
    end

    it 'opens the pane the tab href names, so the strip works with scripting off' do
      doc = show_page(parent, pane: 'children')

      expect(active_pane(doc)).to eq('ref-pane-children')
      expect(doc.at_css('#ref-tab-children')['aria-selected']).to eq('true')
      expect(doc.at_css('#ref-tab-metadata')['aria-selected']).to eq('false')
      href = doc.at_css('#ref-tab-children')['href']
      expect(href).to include('pane=children')
      expect(href).to end_with('#ref-pane-children')
      expect(href).to start_with('?')
    end

    it 'keeps the rest of the query string, so a translated page stays translated' do
      doc = show_page(parent, locale: 'es', pane: 'children')

      expect(doc.at_css('#ref-tab-files')['href']).to include('locale=es')
    end

    it 'stays on the path it was served from, so a nested work keeps its parent' do
      get "/concern/parent/#{child_work.id}/generic_works/#{parent.id}"
      doc = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(doc.at_css('#ref-tab-files')['href']).to start_with('?')
    end

    it 'falls back to the first pane for a pane the work is not showing' do
      container = indexed(GenericWorkResource.new(title: ['Container'], member_ids: [child_work.id]))

      doc = show_page(container, pane: 'files')

      expect(active_pane(doc)).to eq('ref-pane-metadata')
    end

    it 'falls back to the first pane for a pane that does not exist' do
      doc = show_page(parent, pane: 'nonsense')

      expect(active_pane(doc)).to eq('ref-pane-metadata')
    end
  end

  it 'lists an unreadable child work without exposing its title' do
    restricted = indexed(GenericWorkResource.new(title: ['Sealed appendix']))
    parent = indexed(GenericWorkResource.new(title: ['Has a sealed child'], member_ids: [restricted.id]))

    allow_any_instance_of(::Ability).to receive(:can?).and_wrap_original do |original, action, subject|
      id = subject.respond_to?(:id) ? subject.id : subject
      action == :read && id.to_s == restricted.id.to_s ? false : original.call(action, subject)
    end

    doc = show_page(parent)

    expect(response).to have_http_status(:ok)
    expect(doc.at_css('#ref-pane-children .ref-row-name').text.strip).to eq('Private')
    expect(response.body).not_to include('Sealed appendix')
  end
end
