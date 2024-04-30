# frozen_string_literal: true

RSpec.describe Bulkrax::HasMatchersDecorator, type: :decorator do
  subject { entry.matched_metadata(multiple, name, result, object_multiple) }

  let(:entry) { Bulkrax::CsvEntry.new }
  let(:multiple) { true }
  let(:name) { 'based_near' }
  let(:result) { 'San Diego, California, United States' }
  let(:object_multiple) { false }
  let(:account) { FactoryBot.create(:account) }

  before do
    allow_any_instance_of(Site).to receive(:account).and_return(account)
    stub_request(:get, 'http://api.geonames.org/searchJSON')
      .with(query: { q: result, maxRows: 10, username: account.geonames_username })
      .to_return(status: 200, body: File.read('spec/fixtures/geonames_search.json'), headers: {})

    stub_request(:get, 'http://www.geonames.org/getJSON')
      .with(query: hash_including('geonameId': '5391811'))
      .to_return(status: 200, body: File.open(File.join(fixture_path, 'geonames_get.json')))
  end

  describe '#matched_metadata' do
    context 'when given a valid geonames location' do
      it 'returns an Array with a Hyrax::ControlledVocabularies::Location object' do
        expect(entry).to receive(:geonames_lookup).with(result).and_call_original
        expect(subject).to be_an Array
        expect(subject.first).to be_a Hyrax::ControlledVocabularies::Location
        expect(subject.first.full_label).to eq 'San Diego, California, United States'
      end
    end

    context 'when given an invalid geonames location' do
      before do
        stub_request(:get, 'http://api.geonames.org/searchJSON')
          .with(query: { q: result, maxRows: 10, username: account.geonames_username })
          .to_return(status: 200, body: '{ "totalResultsCount": 0, "geonames": [] }', headers: {})
      end

      let(:result) { 'Faketown, Kali4nia, United Steaks' }

      it 'returns an Array with a Hyrax::ControlledVocabularies::Location object' do
        expect(entry).to receive(:geonames_lookup).with(result).and_call_original
        expect(subject).to be_an Array
        expect(subject.first).to be_a Hyrax::ControlledVocabularies::Location
        expect(subject.first.id).to eq 'http://fake#Faketown,%20Kali4nia,%20United%20Steaks'
      end
    end

    context 'when given the URI of a geonames location' do
      let(:result) { 'http://sws.geonames.org/5391811/' }

      it 'returns an Array with a Hyrax::ControlledVocabularies::Location object' do
        expect(entry).not_to receive(:geonames_lookup)
        expect(subject).to be_an Array
        expect(subject.first).to be_a Hyrax::ControlledVocabularies::Location
        expect(subject.first.full_label).to eq 'San Diego, California, United States'
      end
    end

    context 'when given an invalid URI of a geonames location' do
      let(:result) { 'http://fake#Faketown,%20Kali4nia,%20United%20Steaks' }

      it 'returns an Array with a Hyrax::ControlledVocabularies::Location object' do
        expect(entry).not_to receive(:geonames_lookup)
        expect(subject).to be_an Array
        expect(subject.first).to be_a Hyrax::ControlledVocabularies::Location
        expect(subject.first.full_label).to eq 'Faketown, Kali4nia, United Steaks'
      end
    end

    results = [[], nil, '', ' ']
    results.each do |result|
      context "when given a blank value (#{result.inspect})" do
        let(:result) { result }

        it 'returns the original value' do
          expect(entry).not_to receive(:geonames_lookup)
          expect(subject).to eq result
        end
      end
    end
  end
end
