# frozen_string_literal: true

RSpec.describe ControlledVocabularyExport do
  subject(:export) { described_class.new(entry) }

  context 'with a database-backed vocabulary' do
    let(:vocabulary) { Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms') }
    let(:entry) do
      ControlledVocabularyCatalog::Entry.new(source_key: 'reading_rooms', origin: :database, vocabulary: vocabulary,
                                             label: 'Reading Rooms', description: 'Where an item may be consulted.')
    end

    before do
      vocabulary.local_authority_entries.create!(label: 'Special Collections', uri: 'special-collections', position: 2)
      vocabulary.local_authority_entries.create!(label: 'Closed Stacks', uri: 'closed-stacks', position: 1,
                                                 active: false)
    end

    it 'streams csv in the import template columns, in table order' do
      expect(export.csv).to be_a(Enumerator)
      expect(export.csv.to_a).to eq [
        "id,label,active\n",
        "closed-stacks,Closed Stacks,false\n",
        "special-collections,Special Collections,true\n"
      ]
    end

    it 'streams yaml in the qa authority format, carrying the vocabulary metadata' do
      file = YAML.safe_load(export.yml.to_a.join)

      expect(file['source_key']).to eq 'reading_rooms'
      expect(file['label']).to eq 'Reading Rooms'
      expect(file['description']).to eq 'Where an item may be consulted.'
      expect(file['terms']).to eq [
        { 'id' => 'closed-stacks', 'term' => 'Closed Stacks', 'active' => false },
        { 'id' => 'special-collections', 'term' => 'Special Collections', 'active' => true }
      ]
    end

    it 'names the file after the vocabulary' do
      expect(export.filename(:csv)).to eq 'reading_rooms.csv'
      expect(export.filename(:yml)).to eq 'reading_rooms.yml'
    end

    it 'exports past the page display cap' do
      stub_const('ControlledVocabularyCatalog::TERM_LIMIT', 3)
      5.times { |n| vocabulary.local_authority_entries.create!(label: "Term #{n}", uri: "term-#{n}") }

      expect(export.csv.count).to eq 8
    end
  end

  context 'with a config-file vocabulary' do
    let(:entry) { ControlledVocabularyCatalog::Entry.new(source_key: 'map_regions', origin: :file, label: 'Map Regions') }

    before do
      allow(Qa::Authorities::Local).to receive(:subauthority_for).with('map_regions').and_return(
        instance_double(Qa::Authorities::Local::FileBasedAuthority,
                        all: [{ 'id' => 'north', 'label' => 'North' },
                              { 'id' => 'south', 'label' => 'South', 'active' => false }])
      )
    end

    it 'exports the file terms, treating an unstated active flag as true' do
      expect(export.csv.to_a).to eq [
        "id,label,active\n",
        "north,North,true\n",
        "south,South,false\n"
      ]
    end

    it 'exports yaml with the label and no description key' do
      file = YAML.safe_load(export.yml.to_a.join)

      expect(file['source_key']).to eq 'map_regions'
      expect(file['label']).to eq 'Map Regions'
      expect(file).not_to have_key 'description'
      expect(file['terms'].map { |t| t['id'] }).to eq %w[north south]
    end

    it 'reports not found when the file cannot be read' do
      allow(Qa::Authorities::Local).to receive(:subauthority_for)
        .with('map_regions').and_raise(Psych::SyntaxError.allocate)

      expect { export.csv }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with an imported copy of an external vocabulary' do
    let(:vocabulary) { Qa::LocalAuthority.create!(name: 'mesh', label: 'MeSH') }
    let(:entry) do
      ControlledVocabularyCatalog::Entry.new(source_key: 'mesh', origin: :cached, vocabulary: vocabulary)
    end

    before { vocabulary.local_authority_entries.create!(label: 'Diabetes', uri: 'mesh:diabetes') }

    it 'exports the cached rows' do
      expect(entry.downloadable?).to be true
      expect(export.csv.to_a).to include "mesh:diabetes,Diabetes,true\n"
    end
  end
end
