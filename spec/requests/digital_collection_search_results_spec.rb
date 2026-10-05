# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'the digital collection search results page', type: :request, singletenant: true, clean_repo: true do
  let(:doc) { Nokogiri::HTML(response.body) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('digital_collection')
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('digital_collection_show')
  end

  def index_open(resource)
    saved = Hyrax.persister.save(resource:)
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  let!(:collection) do
    index_open(CollectionResource.new(title: ['Maps of the Hudson Valley'], description: ['Survey maps of river towns.'],
                                      collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s))
  end

  let!(:work) do
    index_open(GenericWorkResource.new(title: ['Hudson River map'], creator: ['Colton, J. H.'], date_created: ['1864'],
                                       resource_type: ['Map'], description: ['A folding pocket map of the river.'],
                                       member_of_collection_ids: [collection.id]))
  end

  describe 'a plain search' do
    before { get search_catalog_path(q: 'hudson') }

    it 'shows a visible heading and a results summary' do
      expect(doc.css('h1').map { |h| h.text.strip }).to eq(['Search results'])
      expect(doc.at_css('.dc-results-summary').text).to eq('2 results for “hudson”')
    end

    it 'puts the filters before the results in the page' do
      body = doc.at_css('.dc-results-body')

      expect(body.element_children.map { |el| el['id'] }).to eq(%w[sidebar content])
    end

    it 'hands the translated date range labels to the theme script' do
      facets = doc.at_css('#facets')

      expect([facets['data-dc-range-from'], facets['data-dc-range-to']]).to eq(%w[From To])
      expect(facets['data-dc-range-larger']).to eq('Choose dates in a larger window')
    end

    it 'starts every facet box closed when nothing is filtered' do
      toggles = doc.css('.dc-facet-toggle')

      expect(toggles).not_to be_empty
      expect(toggles.map { |t| t['aria-expanded'] }.uniq).to eq(['false'])
      toggles.each { |t| expect(doc.at_css("##{t['aria-controls']}")).to be_present }
    end

    it 'labels the search chip and follows the chips with Start over' do
      chips = doc.at_css('.dc-constraints-chips')

      expect(chips.at_css('.query .filter-name').text.strip).to eq('Search')
      expect(chips.element_children.last['class']).to include('dc-constraints-start-over')
      expect(chips.element_children.last.text).to eq('Clear search and filters')
      expect(doc.at_css('.dc-constraints-match')).to be_nil
    end

    it 'shows the result range and the labeled Sort by and Per page menus' do
      toolbar = doc.at_css('.dc-toolbar')

      expect(toolbar.at_css('.dc-toolbar-range').text.squish).to eq('1–2 of 2')
      expect(toolbar.css('.dc-toolbar-label').map(&:text)).to eq(['Sort by', 'Per page'])
      expect(toolbar.at_css('#dc-sort-button')['aria-labelledby']).to eq('dc-sort-label dc-sort-button')
    end

    it 'hides the view icons from screen readers and marks the current view' do
      buttons = doc.css('.dc-view-toggle a.dc-control')

      expect(buttons.map { |b| b.at_css('.caption').text }).to include('List', 'Grid', 'Masonry')
      buttons.each { |b| expect(b.at_css('.dc-view-toggle-icon')['aria-hidden']).to eq('true') }
      expect(buttons.select { |b| b['aria-current'] == 'true' }.map { |b| b.at_css('.caption').text }).to eq(['List'])
    end

    it 'shows Creator, Date, Part of, Resource type and Description on work rows, with no title badge' do
      row = doc.css('li.document').find { |li| li.text.include?('Hudson River map') }
      fields = row.css('.dc-result-field').to_h { |f| [f.at_css('dt').text, f.at_css('dd')] }

      expect(fields.keys).to eq(['Creator', 'Date', 'Part of', 'Resource type', 'Description'])
      expect(fields['Part of'].at_css('a').text).to eq('Maps of the Hudson Valley')
      expect(row.at_css('.dc-result-head .badge')).to be_nil
    end

    it 'keeps the work thumbnail link out of the keyboard and screen reader order' do
      link = doc.css('li.document').find { |li| li.text.include?('Hudson River map') }.at_css('.dc-result-thumb a')

      expect(link['tabindex']).to eq('-1')
      expect(link['aria-hidden']).to eq('true')
    end

    it 'shows Description and Works on collection rows' do
      row = doc.css('li.document').find { |li| li.text.include?('Maps of the Hudson Valley') && li.at_css('.dc-result-head')&.text&.include?('Maps') }

      expect(row.css('.dc-result-field dt').map(&:text)).to eq(%w[Description Works])
    end
  end

  it 'opens a facet box that has a chosen value and counts it on the filter toggle' do
    get search_catalog_path(q: 'hudson', f: { creator_sim: ['Colton, J. H.'] })
    toggle = doc.at_css('.blacklight-creator_sim .dc-facet-toggle')

    expect(toggle['aria-expanded']).to eq('true')
    expect(doc.at_css('.dc-facets-toggle .dc-facets-count').text).to include('1')
  end

  it 'marks the current sort in the More window and drops the arrow marks from its pager' do
    get '/catalog/facet/creator_sim', params: { q: 'hudson' }
    sort = doc.at_css('.dc-facet-sort')

    expect(sort.css('.dc-control').map { |c| c.text.strip }).to eq(['A to Z', 'Most results'])
    expect(sort.at_css("[aria-current='true']").text.strip).to eq('Most results')
    expect(doc.at_css('.dc-facet-pager').text.squish).to eq('Previous Next')
  end

  it 'shows a chip and counts the filter when only a date range is applied' do
    get search_catalog_path(range: { date_range_isim: { begin: '1800', end: '1900' } })

    expect(doc.at_css('.dc-constraints-chips .applied-filter .filter-name').text.strip).to eq('Date Range')
    expect(doc.at_css('.dc-facets-toggle .dc-facets-count').text).to start_with('1')
  end

  it 'shows one chip per attribute chosen on the advanced search page' do
    get search_catalog_path(search_field: 'advanced', op: 'AND', title: 'hudson', f_inclusive: { creator_sim: ['Colton, J. H.'] })
    names = doc.css('.dc-constraints-chips .applied-filter .filter-name').map { |n| n.text.strip }

    expect(names).to eq(%w[Title Creator])
    expect(doc.at_css('.dc-constraints-chips').text).not_to include('Any of')
  end

  it 'shows a chip for a year picked from the advanced search Date Range list' do
    get search_catalog_path(search_field: 'advanced', op: 'AND', f_inclusive: { date_range_isim: ['1864'] })
    chip = doc.at_css('.dc-constraints-chips .applied-filter')

    expect(chip.at_css('.filter-name').text.strip).to eq('Date Range')
    expect(chip.at_css('.filter-value').text.strip).to eq('1864')
  end

  it 'shows an advanced search attribute in its facet box once, with one remove link' do
    get search_catalog_path(search_field: 'advanced', op: 'AND', f_inclusive: { creator_sim: ['Colton, J. H.'] })
    box = doc.at_css('.blacklight-creator_sim')

    expect(box.css('.dc-facet-chosen .remove').size).to eq(1)
    expect(box.at_css('.dc-facet-chosen .sr-only').text.strip).to eq('Remove Colton, J. H.')
    expect(box.text).not_to include('Any of')
    expect(box.css('.facet-select').map(&:text)).not_to include('Colton, J. H.')
  end

  it 'leads the chips with the match line after an advanced search with two fields' do
    get search_catalog_path(search_field: 'advanced', op: 'OR', title: 'hudson', creator: 'colton')

    expect(doc.at_css('.dc-constraints-match').text.squish).to eq('Matching any of these fields:')
  end

  %w[de es fr it pt-BR zh].each do |locale|
    it "translates the Sort by choices in #{locale}" do
      get search_catalog_path(q: 'hudson', locale:)
      choices = doc.css('.dc-toolbar .dropdown-menu .dropdown-item').map { |a| a.text.strip }

      expect(choices.first).to eq(I18n.t('blacklight.search.fields.sort.score desc, system_create_dtsi desc', locale:))
      expect(choices).to include(I18n.t('blacklight.search.fields.sort.title_ssi asc', locale:))
      expect(choices).not_to include('Relevance', 'Title')
    end

    it "has every label translated in #{locale}" do
      get search_catalog_path(q: 'hudson', locale:)

      expect(response.body).not_to include('translation_missing')
      expect(doc.at_css('h1').text).to eq(I18n.t('digital_collection.search.results.heading', locale:))
    end
  end
end
