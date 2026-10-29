# frozen_string_literal: true

RSpec.describe Hyrax::HyraxHelperBehaviorDecorator, type: :helper do
  describe '#link_to_value_facet' do
    let(:config) do
      ::CatalogController.blacklight_config.deep_copy.tap do |blacklight|
        blacklight.add_facet_field('resource_type_label_sim') unless blacklight.facet_fields.key?('resource_type_label_sim')
      end
    end
    let(:anchor) { Nokogiri::HTML.fragment(link).at_css('a') }
    let(:href) { CGI.unescape(anchor['href']) }

    before do
      blacklight = config
      helper.define_singleton_method(:blacklight_config) { blacklight }
      helper.define_singleton_method(:search_state) { Blacklight::SearchState.new({}, blacklight) }
    end

    context 'with an indexed label the catalog facets on' do
      let(:link) { helper.link_to_value_facet('summertime', 'Pink Pajamas', 'resource_type_sim') }

      it 'links the label through the label facet' do
        expect(anchor.text).to eq 'Pink Pajamas'
        expect(href).to include('f[resource_type_label_sim][]=Pink Pajamas')
        expect(href).not_to include('f[resource_type_sim]')
      end
    end

    context 'with no indexed label, as on a document indexed before labels' do
      let(:link) { helper.link_to_value_facet('summertime', nil, 'resource_type_sim') }

      it 'links the stored value through its own facet' do
        expect(anchor.text).to eq 'summertime'
        expect(href).to include('f[resource_type_sim][]=summertime')
      end
    end

    context 'when the catalog has no label facet for the field' do
      let(:link) { helper.link_to_value_facet('car-1', 'Car', 'vehicle_type_sim') }

      it 'shows the label and links the stored value through its own facet' do
        expect(anchor.text).to eq 'Car'
        expect(href).to include('f[vehicle_type_sim][]=car-1')
      end
    end
  end
end
