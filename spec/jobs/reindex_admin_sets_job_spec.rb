# frozen_string_literal: true

RSpec.describe ReindexAdminSetsJob do
  describe '#perform' do
    let(:admin_set_classes) { [AdminSetResource] }

    before do
      allow(Hyrax::ModelRegistry).to receive(:admin_set_classes).and_return(admin_set_classes)
      allow(Hyrax.query_service).to receive(:find_all_of_model).and_return([])
    end

    context 'when Wings is disabled' do
      before { allow(Hyrax.config).to receive(:disable_wings).and_return(true) }

      it 'queries with the Valkyrie resource class directly' do
        described_class.perform_now
        expect(Hyrax.query_service).to have_received(:find_all_of_model).with(model: AdminSetResource)
      end
    end

    context 'when Wings is enabled' do
      before do
        skip 'Wings::ModelRegistry is not loaded in no-Wings mode' if Hyrax.config.disable_wings
        allow(Hyrax.config).to receive(:disable_wings).and_return(false)
        allow(Wings::ModelRegistry).to receive(:lookup).with(AdminSetResource).and_return(AdminSetResource)
      end

      it 'resolves models through Wings::ModelRegistry' do
        described_class.perform_now
        expect(Wings::ModelRegistry).to have_received(:lookup).with(AdminSetResource)
      end
    end
  end
end
