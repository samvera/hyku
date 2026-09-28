# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DateRangeIndexing do
  let(:base_indexer) do
    Class.new do
      attr_reader :resource

      def initialize(resource:)
        @resource = resource
      end

      def generate_solr_document(*_args, **_kwargs)
        { 'title_tesim' => ['Untouched'] }
      end

      def to_solr(*_args, **_kwargs)
        { 'title_tesim' => ['Untouched'] }
      end
    end
  end

  let(:indexer_class) do
    Class.new(base_indexer) do
      include DateRangeIndexing

      def date_properties
        %i[date_created]
      end
    end
  end

  let(:work) { Struct.new(:date_created, keyword_init: true) }
  let(:solr_field) { described_class::SOLR_FIELD }

  def index(**dates)
    indexer_class.new(resource: work.new(**dates)).to_solr
  end

  it 'indexes the creation year' do
    expect(index(date_created: '1911')[solr_field]).to eq [1911]
  end

  it 'reads an array-valued property' do
    expect(index(date_created: ['1911', '1962'])[solr_field]).to eq [1911, 1962]
  end

  it 'omits the field when no property has a value' do
    expect(index).not_to have_key solr_field
  end

  it 'omits the field when the values are the "[]" sentinel' do
    expect(index(date_created: '[]')).not_to have_key solr_field
  end

  it 'omits the field when no value parses' do
    expect(index(date_created: 'n.d.')).not_to have_key solr_field
  end

  it 'leaves the rest of the document alone' do
    expect(index(date_created: '1911')['title_tesim']).to eq ['Untouched']
  end

  describe 'generate_solr_document (ActiveFedora path)' do
    def index_af(**dates)
      indexer_class.new(resource: work.new(**dates)).generate_solr_document
    end

    it 'indexes the creation year through the ActiveFedora method' do
      expect(index_af(date_created: '1911')[solr_field]).to eq [1911]
    end
  end

  context 'with a resource that lacks the date property' do
    let(:work) { Struct.new(:title, keyword_init: true) }

    it 'omits the field rather than raising' do
      expect(index(title: ['No dates here'])).not_to have_key solr_field
    end
  end
end
