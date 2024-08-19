# frozen_string_literal: true

require 'rails_helper'

module Bulkrax
  RSpec.describe OerCsvParser do
    subject           { CsvParser.new(importer) }

    let(:importer)    { FactoryBot.create(:bulkrax_importer_oer_csv) }
    let(:oer_entry_1) { FactoryBot.build(:bulkrax_oer_csv_entry, importerexporter: importer, identifier: 'oer_1') }
    let(:oer_entry_2) { FactoryBot.build(:bulkrax_oer_csv_entry, importerexporter: importer, identifier: 'oer_2') }
    let(:oer_entry_3) { FactoryBot.build(:bulkrax_oer_csv_entry, importerexporter: importer, identifier: 'oer_3') }
    let(:oer_entry_4) { FactoryBot.build(:bulkrax_oer_csv_entry, importerexporter: importer, identifier: 'oer_4') }

    before do
      allow(Bulkrax::CsvEntry).to receive(:where).with(identifier: 'oer_1', importerexporter_id: importer.id, importerexporter_type: 'Bulkrax::Importer').and_return([oer_entry_1])
      allow(Bulkrax::CsvEntry).to receive(:where).with(identifier: 'oer_2', importerexporter_id: importer.id, importerexporter_type: 'Bulkrax::Importer').and_return([oer_entry_2])
      allow(Bulkrax::CsvEntry).to receive(:where).with(identifier: 'oer_3', importerexporter_id: importer.id, importerexporter_type: 'Bulkrax::Importer').and_return([oer_entry_3])
      allow(Bulkrax::CsvEntry).to receive(:where).with(identifier: 'oer_4', importerexporter_id: importer.id, importerexporter_type: 'Bulkrax::Importer').and_return([oer_entry_4])
    end

    describe '#records_with_previous_versions' do
      it 'returns a hash of identifiers with previous versions' do
        expect(subject.records_with_previous_versions).to eq('oer_1' => ['oer_4'])
      end

      context 'with complex relationships' do
        let(:importer) { FactoryBot.create(:bulkrax_importer_oer_csv_complex) }

        it 'parses complex related items appropriately' do
          expect(subject.records_with_previous_versions).to eq('oer_1' => ['oer_4', 'oer_3'], 'oer_2' => ['oer_1'])
        end
      end
    end

    describe '#records_with_newer_versions' do
      it 'returns a hash of identifiers with newer versions' do
        expect(subject.records_with_newer_versions).to eq('oer_2' => ['oer_3'])
      end
    end

    describe '#records_with_alternate_versions' do
      it 'returns a hash of identifiers with alternate versions' do
        expect(subject.records_with_alternate_versions).to eq('oer_3' => ['oer_2'])
      end

      context 'with complex relationships' do
        let(:importer) { FactoryBot.create(:bulkrax_importer_oer_csv_complex) }

        it 'parses complex related items appropriately' do
          expect(subject.records_with_alternate_versions).to eq('oer_3' => ['oer_2', 'oer_4'], 'oer_4' => ['oer_2'])
        end
      end
    end

    describe '#records_with_related_items' do
      it 'returns a hash of identifiers with related items' do
        expect(subject.records_with_related_items).to eq('oer_4' => ['oer_1'])
      end
    end

    describe '#create_previous_version_relationships' do
      it 'invokes Bulkrax::RelatedMembershipsJob' do
        expect(Bulkrax::RelatedMembershipsJob).to receive(:perform_later).exactly(1).times
        subject.create_previous_version_relationships
      end
    end

    describe '#create_newer_version_relationships' do
      it 'invokes Bulkrax::RelatedMembershipsJob' do
        expect(Bulkrax::RelatedMembershipsJob).to receive(:perform_later).exactly(1).times
        subject.create_newer_version_relationships
      end
    end

    describe '#create_alternate_version_relationships' do
      it 'invokes Bulkrax::RelatedMembershipsJob' do
        expect(Bulkrax::RelatedMembershipsJob).to receive(:perform_later).exactly(1).times
        subject.create_alternate_version_relationships
      end
    end

    describe '#create_related_item_relationships' do
      it 'invokes Bulkrax::RelatedMembershipsJob' do
        expect(Bulkrax::RelatedMembershipsJob).to receive(:perform_later).exactly(1).times
        subject.create_related_item_relationships
      end
    end
  end
end
