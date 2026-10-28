# frozen_string_literal: true

RSpec.describe Hyku::CatalogConfigCopyDecorator do
  let(:catalog_config) do
    ::CatalogController.blacklight_config.deep_copy.tap { |config| config.add_index_field('extent_tesim', label: 'Extent') }
  end

  [Hyrax::GenericWorksController, Hyrax::CollectionsController, Hyrax::FileSetsController,
   Hyrax::SingleUseLinksViewerController].each do |copier|
    context "on #{copier}" do
      let(:controller) { copier.new.tap { |instance| instance.request = ActionDispatch::TestRequest.create } }

      before do
        allow(::CatalogController).to receive(:new).and_return(instance_double(::CatalogController, blacklight_config: catalog_config))
      end

      it "takes the catalog's search result fields for each request" do
        expect(controller.blacklight_config.index_fields.keys).to eq(catalog_config.index_fields.keys)
      end

      it "keeps the controller's own search settings and leaves its class config alone" do
        expect(controller.blacklight_config.search_builder_class).to eq(copier.blacklight_config.search_builder_class)
        expect(copier.blacklight_config.index_fields).not_to have_key('extent_tesim')
      end

      it "answers the catalog's field conditions" do
        field = Blacklight::Configuration::IndexField.new(key: 'resource_type_tesim')

        expect(controller.send(:render_in_tenant?, field, SolrDocument.new)).to be(true)
        expect(controller.send(:render_optionally?, field, SolrDocument.new)).to be(true)
      end

      it 'links field values to catalog searches' do
        expect(URI(controller.send(:search_action_url, f: { 'creator_sim' => ['me'] })).path).to eq('/catalog')
      end
    end
  end
end
