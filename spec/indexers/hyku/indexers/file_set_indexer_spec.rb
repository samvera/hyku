# frozen_string_literal: true

RSpec.describe Hyku::Indexers::FileSetIndexer do
  let(:indexer_class) { described_class }
  let(:resource)      { Hyrax.config.file_set_model.constantize.new }
  let(:original_file) { Hyrax::FileMetadata.new }

  it 'is the configured file set indexer' do
    expect(Hyrax.config.file_set_indexer).to eq described_class
  end

  describe '#to_solr' do
    let(:stream) { File.open('spec/fixtures/pdf/pdf_sample.pdf').read }
    it 'indexes the text of a pdf that has text already' do
      allow(Flipflop).to receive(:default_pdf_viewer?).and_return(true)
      allow(resource).to receive(:original_file).and_return(original_file)
      allow(original_file).to receive(:pdf?).and_return(true)
      allow(original_file).to receive(:content).and_return(stream)

      expect(resource.to_solr['all_text_tsimv']).to include('Dummy PDF file')
    end
  end
end
