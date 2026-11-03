# frozen_string_literal: true

RSpec.describe Hyrax::MyController, '#blacklight_config' do
  let(:catalog_config) { ::CatalogController.blacklight_config.deep_copy }

  before do
    allow(::CatalogController).to receive(:new).and_return(instance_double(::CatalogController, blacklight_config: catalog_config))
  end

  [Hyrax::My::WorksController, Hyrax::My::CollectionsController,
   Hyrax::Dashboard::WorksController, Hyrax::Dashboard::CollectionsController].each do |dashboard|
    context "on #{dashboard}" do
      let(:facet_fields) { dashboard.new.blacklight_config.facet_fields }

      context 'when the catalog facets resource type on its labels' do
        before { catalog_config.add_facet_field 'resource_type_label_sim', label: 'Type' }

        it 'facets resource type on its labels in the same place' do
          expect(facet_fields.keys).to eq(dashboard.blacklight_config.facet_fields.keys.map { |key| key.sub('resource_type_sim', 'resource_type_label_sim') })
        end

        it "keeps the dashboard's own label for the facet" do
          expect(facet_fields['resource_type_label_sim'].display_label('facet')).to eq('Resource Type')
        end

        it "leaves the controller's class config alone" do
          facet_fields

          expect(dashboard.blacklight_config.facet_fields).to have_key('resource_type_sim')
          expect(dashboard.blacklight_config.facet_fields).not_to have_key('resource_type_label_sim')
        end
      end

      context 'when the catalog facets resource type on its stored values' do
        it 'keeps the stored-value facet' do
          expect(facet_fields.keys).to eq(dashboard.blacklight_config.facet_fields.keys)
        end
      end
    end
  end

  context 'when the catalog facets another dashboard field on its labels' do
    before { catalog_config.add_facet_field 'admin_set_label_sim', label: 'Admin set' }

    it 'facets that field on its labels too' do
      expect(Hyrax::My::WorksController.new.blacklight_config.facet_fields.keys)
        .to include('admin_set_label_sim').and include('resource_type_sim')
    end
  end
end
