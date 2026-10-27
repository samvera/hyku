# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThemeLabelHelper, type: :helper do
  describe '#theme_values' do
    let(:uri) { 'http://id.loc.gov/authorities/names/n79021164' }

    it "shows a document's indexed label for each stored value" do
      document = SolrDocument.new('creator_tesim' => [uri, 'Ada Lovelace'], 'creator_label_tesim' => ['Twain, Mark', 'Ada Lovelace'])

      expect(helper.theme_values(document, :creator)).to eq ['Twain, Mark', 'Ada Lovelace']
    end

    it 'falls back to the stored value, a URI included, when no label is indexed' do
      document = SolrDocument.new('creator_tesim' => [uri])

      expect(helper.theme_values(document, :creator)).to eq [uri]
    end

    it "falls back to a term's stored value when its indexed label is blank" do
      document = SolrDocument.new('creator_tesim' => [uri], 'creator_label_tesim' => [''])

      expect(helper.theme_values(document, :creator)).to eq [uri]
    end

    it "uses a presenter's show page values" do
      presenter = double('presenter', creator: [uri], display_values_for: ['Twain, Mark'])

      expect(helper.theme_values(presenter, :creator)).to eq ['Twain, Mark']
      expect(presenter).to have_received(:display_values_for).with(:creator)
    end
  end

  describe '#theme_facet_list' do
    let(:uri) { 'http://example.org/keywords/k1' }
    let(:document) { SolrDocument.new('keyword_tesim' => [uri], 'keyword_label_tesim' => ['Lighthouses']) }
    let(:config) { Blacklight::Configuration.new.tap { |blacklight| blacklight.add_facet_field('keyword_sim') } }
    let(:links) { Capybara.string(helper.theme_facet_list(document, :keyword, 'none')) }

    before do
      blacklight = config
      helper.define_singleton_method(:blacklight_config) { blacklight }
      helper.define_singleton_method(:search_state) { Blacklight::SearchState.new({}, blacklight) }
    end

    it "links each label through the label facet when the catalog registers one" do
      config.add_facet_field('keyword_label_sim')

      expect(links).to have_link('Lighthouses', href: /f%5Bkeyword_label_sim%5D%5B%5D=Lighthouses/)
    end

    it 'shows the label but links the stored value through the id facet otherwise' do
      expect(links).to have_link('Lighthouses', href: /f%5Bkeyword_sim%5D%5B%5D=#{CGI.escape(uri)}/)
    end

    it 'shows the empty message when there are no values' do
      expect(helper.theme_facet_list(SolrDocument.new({}), :keyword, 'none')).to eq 'none'
    end
  end
end
