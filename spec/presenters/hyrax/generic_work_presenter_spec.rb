# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work GenericWork`
require 'rails_helper'

RSpec.describe Hyrax::GenericWorkPresenter do
  let(:solr_document) do
    SolrDocument.new(
      id: '123abc',
      'bulkrax_identifier_tesim' => ['abc123']
    )
  end

  let(:presenter) { described_class.new(solr_document, nil) }

  describe '#bulkrax_identifier' do
    it 'returns the bulkrax_identifier from solr_document' do
      expect(presenter.bulkrax_identifier).to eq('abc123')
    end
  end

  it "exists" do
    expect(described_class).to be_a(Class)
  end
end
