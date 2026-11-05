# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'the digital collection advanced search page', type: :request, singletenant: true, clean_repo: true do
  let(:doc) { Nokogiri::HTML(response.body) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('digital_collection')
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('digital_collection_show')
  end

  describe 'the advanced search form' do
    before { get '/advanced' }

    it 'keeps Start over out of the page heading' do
      expect(doc.css('h1').map { |h| h.text.strip }).to eq(['More Search Options'])
      expect(doc.css('a.dc-advanced-start-over').size).to eq(1)
    end

    it 'leaves the Advanced search link out of the search bar' do
      expect(doc.at_css('#advanced-top-button')).to be_nil
    end

    it 'groups the fields and the attributes under their own legends' do
      legends = doc.css('fieldset.dc-advanced-criteria > legend').map { |l| l.text.squish }

      expect(legends.first).to start_with('Find items that match')
      expect(legends.first).to end_with('of these fields')
      expect(legends.last).to eq('And have these attributes')
    end

    it 'names the all or any menu for screen readers' do
      expect(doc.at_css('select#op.dc-advanced-op')['aria-label']).to eq('Match all or any fields')
    end

    it 'labels every search field above its input' do
      fields = doc.css('#advanced_search .dc-advanced-field')

      expect(fields).not_to be_empty
      fields.each do |field|
        input = field.at_css('input.form-control')
        expect(field.at_css("label[for='#{input['id']}']")).to be_present
      end
    end

    it "shows Hyku's search tips in a labeled side panel" do
      tips = doc.at_css('aside.dc-advanced-tips')

      expect(tips['aria-labelledby']).to eq('dc-advanced-tips-heading')
      expect(tips.at_css('h2#dc-advanced-tips-heading').text).to eq('Search tips')
      expect(tips.css('li').size).to eq(9)
      expect(tips.text).to include('Search by date with format: YYYYMMDD, YYYYMM or YYYY.')
    end

    it 'opens the form with the sort menu, Start over and Search' do
      submit = doc.at_css('form.dc-advanced-form > .dc-advanced-submit')

      expect(submit.next_element['class']).to include('dc-advanced-criteria')

      expect(submit.at_css("label[for='sort']")).to be_present
      expect(submit.at_css('a.dc-advanced-start-over').text).to eq('Start over')
      expect(submit.at_css('input#advanced-search-submit')['value']).to eq('Search')
    end
  end

  %w[en de es fr it pt-BR zh].each do |locale|
    it "has every label translated in #{locale}" do
      get '/advanced', params: { locale: }

      expect(response.body).not_to include('translation_missing')
      expect(doc.at_css('#advanced-search-submit')['value']).to eq(I18n.t('blacklight_advanced_search.form.search_btn', locale:))
      expect(doc.at_css('select#op option')['value']).to eq('AND')
      expect(doc.at_css("label[for='title']").text).to eq(I18n.t('blacklight.search.fields.search.title', locale:, default: 'Title'))
    end
  end

  it 'keeps the Advanced search link in the search bar on other catalog pages' do
    get search_catalog_path(q: 'maps')

    expect(doc.at_css('.dc-searchbar #advanced-top-button')).to be_present
  end
end
