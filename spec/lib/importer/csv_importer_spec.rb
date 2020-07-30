# frozen_string_literal: true

require 'importer'

RSpec.describe Importer::CSVImporter do
  let(:image_directory) { 'spec/fixtures/images' }

  context 'when the model is passed' do
    let(:csv_file) { "#{fixture_path}/csv/gse_metadata.csv" }
    let(:importer) { described_class.new(csv_file, image_directory, fallback_class) }
    let(:fallback_class) { Class.new { def initialize(_argx, _argy); end } }
    let(:factory) { double(run: true) }

    # note: 2 rows do not specify type, 17 do
    it 'creates new works' do
      expect(fallback_class).to receive(:new)
        .with(any_args).and_return(factory).twice
      expect(Importer::Factory::ETDFactory).to receive(:new)
        .with(any_args).and_return(factory).exactly(17).times
      importer.import_all
    end
  end

  context 'when the model specified on the row' do
    let(:csv_file) { "#{fixture_path}/csv/sample.csv" }
    let(:importer) { described_class.new(csv_file, image_directory) }
    let(:collection_factory) { double }
    let(:image_factory) { double }

    it 'creates new images and collections' do
      expect(Importer::Factory::CollectionFactory).to receive(:new)
        .with(hash_excluding(:type), image_directory)
        .and_return(collection_factory)
      expect(collection_factory).to receive(:run)
      expect(Importer::Factory::ImageFactory).to receive(:new)
        .with(hash_excluding(:type), image_directory)
        .and_return(collection_factory)
      expect(collection_factory).to receive(:run)
      expect(Importer::Factory::ETDFactory).to receive(:new)
        .with(hash_excluding(:type), image_directory)
        .and_return(image_factory)
      expect(image_factory).to receive(:run)
      importer.import_all
    end
  end
end
