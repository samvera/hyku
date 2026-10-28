# frozen_string_literal: true

RSpec.describe Hyku::BlacklightHelperBehavior, type: :helper do
  describe '#document_presenter_class' do
    let(:config) { ::CatalogController.blacklight_config }

    before do
      blacklight = config
      helper.define_singleton_method(:blacklight_config) { blacklight }
    end

    it "presents a collection page's members as search results" do
      allow(helper).to receive_messages(controller: Hyrax::CollectionsController.new, action_name: 'show', document_index_view_type: :gallery)

      expect(helper.document_presenter_class).to eq(config.view_config(:gallery).document_presenter_class)
    end

    it 'keeps the show presenter on other show pages' do
      allow(helper).to receive_messages(controller: CatalogController.new, action_name: 'show')

      expect(helper.document_presenter_class).to eq(config.show.document_presenter_class)
    end
  end
end
