# frozen_string_literal: true

RSpec.describe ReindexCollectionsJob do
  describe '#perform' do
    let(:collection_classes) { [CollectionResource] }

    before do
      allow(Hyrax::ModelRegistry).to receive(:collection_classes).and_return(collection_classes)
      allow(Hyrax.query_service).to receive(:find_all_of_model).and_return([])
    end

    context 'when Wings is disabled' do
      before { allow(Hyrax.config).to receive(:disable_wings).and_return(true) }

      it 'queries with the Valkyrie resource class directly' do
        described_class.perform_now
        expect(Hyrax.query_service).to have_received(:find_all_of_model).with(model: CollectionResource)
      end
    end

    context 'when Wings is enabled',
            skip: (Hyrax.config.disable_wings ? 'Wings::ModelRegistry is not loaded in no-Wings mode' : false) do
      before do
        allow(Hyrax.config).to receive(:disable_wings).and_return(false)
        allow(Wings::ModelRegistry).to receive(:lookup).with(CollectionResource).and_return(CollectionResource)
      end

      it 'resolves models through Wings::ModelRegistry' do
        described_class.perform_now
        expect(Wings::ModelRegistry).to have_received(:lookup).with(CollectionResource)
      end
    end
  end
end
