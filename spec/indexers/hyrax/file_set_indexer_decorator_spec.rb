# frozen_string_literal: true

RSpec.describe Hyrax::FileSetIndexerDecorator, type: :decorator do
  let(:user)           { FactoryBot.create(:user) }
  let(:file_set)       { create(:file_set) }
  let(:relation)       { :original_file }
  let(:actor)          { Hyrax::Actors::FileActor.new(file_set, relation, user) }
  let(:file_path)      { File.join(file_fixture_path, 'pdf', 'archive.pdf') }
  let(:fixture)        { fixture_file_upload(file_path, 'application/pdf') }
  let(:huf)            { Hyrax::UploadedFile.new(user:, file_set_uri: file_set.uri, file: fixture) }
  let(:io)             { JobIoWrapper.new(file_set_id: file_set.id, user:, uploaded_file: huf) }
  let(:solr_document)  { SolrDocument.find(file_set.id) }
  let!(:test_strategy) { Flipflop::FeatureSet.current.test! }

  describe '#generate_solr_document' do
    it 'adds PDF text to solr document when PDF.js' do
      test_strategy.switch!(:default_pdf_viewer, true)
      actor.ingest_file(io)
      ###############################################################################################################
      ## Due to the base image, this test does not work; it requires that pdftotext be installed
      # expect(solr_document['all_text_tsimv'].first).to start_with("; ORIGINALITY AUTHENTICITY LEGACY KJ? Kolbe 6?")
      expect(solr_document).to have_key('all_text_tsimv')
    end
  end
end
