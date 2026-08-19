# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ControlledVocabularyCatalog do
  # The suite seeds every real yaml vocabulary into the tables, so an unstubbed
  # file_based_names would be entirely claimed by database rows. Naming a fictional
  # file set keeps these examples independent of that seed state, and clear of
  # Qa::LocalAuthority's validation against shadowing a real yaml file.
  #
  # `map_regions` stands for a file present on disk, `geo_regions` for one named in
  # a profile but missing, so the uncountable path is covered too.
  before do
    allow(described_class).to receive(:file_based_names).and_return(%w[map_regions geo_regions])
    allow(Qa::Authorities::Local).to receive(:subauthority_for).and_call_original
    allow(Qa::Authorities::Local).to receive(:subauthority_for)
      .with('map_regions').and_return(instance_double(Qa::Authorities::Local::FileBasedAuthority,
                                                      all: [{ id: 'north', label: 'North' }]))
  end

  describe '.all' do
    it 'includes file-based and remote authorities alongside the editable ones' do
      Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms')

      expect(described_class.all.map(&:origin).uniq).to include(:database, :file, :remote)
    end

    it 'lists editable vocabularies first' do
      Qa::LocalAuthority.create!(name: 'zzz_last_alphabetically', label: 'Zzz')

      expect(described_class.all.first.origin).to eq :database
    end

    it 'gives every authority a source key a profile can cite' do
      expect(described_class.all.map(&:source_key)).to all(be_present)
    end

    it 'does not list the same source key twice' do
      keys = described_class.all.map(&:source_key)

      expect(keys).to eq keys.uniq
    end
  end

  describe '.database' do
    let!(:vocabulary) { Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms') }

    before do
      vocabulary.local_authority_entries.create!(label: 'Special Collections', uri: 'special-collections')
      vocabulary.local_authority_entries.create!(label: 'Closed Stacks', uri: 'closed-stacks', active: false)
    end

    it 'counts the terms in the tenant' do
      entry = described_class.database.detect { |e| e.source_key == 'reading_rooms' }

      expect(entry.term_count).to eq 2
    end

    it 'is editable' do
      entry = described_class.database.detect { |e| e.source_key == 'reading_rooms' }

      expect(entry).to be_editable
    end
  end

  describe '.file_based' do
    it 'lists the yaml vocabularies no database row claims' do
      expect(described_class.file_based.map(&:source_key)).to contain_exactly('map_regions', 'geo_regions')
    end

    it 'is not editable' do
      expect(described_class.file_based.map(&:editable?).uniq).to eq [false]
    end

    # The row is what staff see and edit, so listing both would read as two
    # separate vocabularies.
    it 'omits a name a database row already claims' do
      Qa::LocalAuthority.create!(name: 'map_regions')

      expect(described_class.file_based.map(&:source_key)).to contain_exactly('geo_regions')
    end

    it 'counts the terms in the yaml file' do
      entry = described_class.file_based.detect { |e| e.source_key == 'map_regions' }

      expect(entry.term_count).to be_positive
    end

    # A yaml file named in the profile but absent from disk must not blow up the
    # whole listing.
    it 'reports an uncountable vocabulary rather than claiming it is empty' do
      entry = described_class.file_based.detect { |e| e.source_key == 'geo_regions' }

      expect(entry.term_count).to be_nil
    end
  end

  describe '.remote' do
    it 'names the service instead of counting terms' do
      entry = described_class.remote.detect { |e| e.source_key == 'loc/subjects' }

      expect(entry.provider).to eq 'loc'
      expect(entry.term_count).to be_nil
    end

    it 'is not editable' do
      expect(described_class.remote.map(&:editable?).uniq).to eq [false]
    end

    it 'names the service behind each authority' do
      expect(described_class.remote.detect { |e| e.source_key == 'getty/aat' }.provider).to eq 'getty'
    end

    # Titleizing the key gives "Getty/Aat", which names neither the service nor the
    # vocabulary usefully. The service has its own column, so the label carries the
    # vocabulary.
    it 'names the vocabulary, spelling out acronyms' do
      entry = described_class.remote.detect { |e| e.source_key == 'getty/aat' }

      expect(entry.label).to eq 'Art & Architecture Thesaurus'
    end

    it 'falls back to the service name for a single-vocabulary service' do
      expect(described_class.remote.detect { |e| e.source_key == 'geonames' }.label).to eq 'GeoNames'
    end

    it 'flags a service whose credentials are missing' do
      allow(Qa::Authorities::Geonames).to receive(:username).and_return(nil)

      expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).not_to be_configured
    end

    it 'does not flag a service that needs no credentials' do
      expect(described_class.remote.detect { |e| e.source_key == 'loc/subjects' }).to be_configured
    end

    # mesh is registered as remote but its url points at a local table, so it is
    # not an external service.
    it 'omits authorities whose url is a local lookup' do
      expect(described_class.remote.map(&:source_key)).not_to include 'mesh'
    end
  end

  describe 'a registered local authority with no terms yet' do
    it 'is listed as local, awaiting its import task' do
      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(entry.origin).to eq :database
      expect(entry.term_count).to eq 0
      expect(entry).to be_awaiting_import
      expect(entry.import_task).to eq 'mesh:import_tenant'
    end

    # There is no row to open, so the listing must not link it.
    it 'is not editable, because it has no record yet' do
      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(entry).not_to be_editable
      expect(entry).to be_local
      expect(entry.vocabulary).to be_nil
    end

    it 'stops awaiting import once terms exist' do
      vocabulary = Qa::LocalAuthority.create!(name: 'mesh')
      vocabulary.local_authority_entries.create!(label: 'Diabetes', uri: 'mesh:diabetes')

      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(entry).not_to be_awaiting_import
    end
  end

  # Qa::Authorities::LocalVocabulary decides per call: a database row serves the
  # terms, and a vocabulary with no row falls back to its yaml file. So a row and a
  # file of the same name are one vocabulary, listed once, served from the row.
  describe 'a vocabulary with both a database row and a yaml file' do
    before { Qa::LocalAuthority.create!(name: 'map_regions') }

    it 'is listed once, as editable' do
      matching = described_class.all.select { |e| e.source_key == 'map_regions' }

      expect(matching.size).to eq 1
      expect(matching.first).to be_editable
    end

    it 'is not listed as file-based' do
      expect(described_class.file_based.map(&:source_key)).not_to include 'map_regions'
    end
  end
end
