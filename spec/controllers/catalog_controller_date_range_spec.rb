# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController do
  let(:config) { described_class.blacklight_config }
  let(:facet) { config.facet_fields[DateRangeIndexing::SOLR_FIELD] }

  describe 'the date range facet' do
    it 'is configured on the field the indexers write' do
      expect(facet).to be_present
    end

    it 'is a range facet' do
      expect(facet.range).to be true
    end

    it 'pins the chart to a readable window' do
      expect(facet.range_config[:assumed_boundaries]).to eq [1800, Time.zone.now.year + 2]
    end

    it 'reaches Solr' do
      expect(config.add_facet_fields_to_solr_request).to be true
    end

    it 'stays out of the advanced search facet selects' do
      expect(facet.include_in_advanced_search).to be false
    end
  end
end
