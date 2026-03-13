# frozen_string_literal: true

RSpec.describe ReindexWorksJob do
  describe '#perform (bulk reindex)' do
    let(:work_classes) { [GenericWorkResource, ImageResource] }

    before do
      allow(Hyrax::ModelRegistry).to receive(:work_classes).and_return(work_classes)
      allow(Hyrax.query_service).to receive(:find_all_of_model).and_return([])
    end

    context 'when Wings is disabled' do
      before { allow(Hyrax.config).to receive(:disable_wings).and_return(true) }

      it 'queries with the Valkyrie resource class directly' do
        described_class.perform_now

        work_classes.each do |klass|
          expect(Hyrax.query_service).to have_received(:find_all_of_model).with(model: klass)
        end
      end
    end

    context 'when Wings is enabled' do
      before do
        skip 'Wings::ModelRegistry is not loaded in no-Wings mode' if Hyrax.config.disable_wings
        allow(Hyrax.config).to receive(:disable_wings).and_return(false)
        work_classes.each do |klass|
          allow(Wings::ModelRegistry).to receive(:lookup).with(klass).and_return(klass)
        end
      end

      it 'resolves models through Wings::ModelRegistry' do
        described_class.perform_now

        work_classes.each do |klass|
          expect(Wings::ModelRegistry).to have_received(:lookup).with(klass)
        end
      end
    end
  end
end
