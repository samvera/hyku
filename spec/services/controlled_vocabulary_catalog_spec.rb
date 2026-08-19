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

    # An empty vocabulary is where the first term gets added, so having no terms must
    # not close the page that adds them.
    it 'is editable and viewable before it has any terms' do
      Qa::LocalAuthority.create!(name: 'lab_names', label: 'Lab Names')

      entry = described_class.database.detect { |e| e.source_key == 'lab_names' }

      expect(entry.term_count).to eq 0
      expect(entry).to be_editable
      expect(entry).to be_viewable
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

    # The list comes from qa, not a hand-maintained hash, so every subauthority the
    # gem supports is offered and each key is one qa can actually resolve.
    it 'offers every subauthority the gem reports' do
      keys = described_class.remote.map(&:source_key)

      expect(keys).to include(*Qa::Authorities::Getty.subauthorities.map { |s| "getty/#{s}" })
    end

    it 'spells a subauthority the way qa expects it' do
      keys = described_class.remote.map(&:source_key)

      expect(keys).to include 'loc/genreForms'
      expect(keys).not_to include 'loc/genre_forms'
    end

    it 'picks up a service the previous hardcoded list omitted' do
      expect(described_class.remote.map(&:provider)).to include 'crossref'
    end

    # mesh reads a local table, so it is not an external service.
    it 'omits mesh' do
      expect(described_class.remote.map(&:source_key)).not_to include 'mesh'
    end

    # Read from this tenant's settings, not from Qa::Authorities::Geonames.username:
    # that is a class_attribute holding whichever tenant configured Hyrax last.
    context 'with a tenant' do
      let(:account) { instance_double(Account, settings: settings) }

      before { allow(Site).to receive(:account).and_return(account) }

      context 'whose credentials are set' do
        let(:settings) { { 'geonames_username' => 'scientist' } }

        it 'does not flag the service' do
          expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).to be_configured
        end
      end

      context 'whose credentials are missing' do
        let(:settings) { { 'geonames_username' => '' } }

        it 'flags the service' do
          expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).not_to be_configured
        end

        it 'leaves a service that needs no credentials alone' do
          expect(described_class.remote.detect { |e| e.source_key == 'loc/subjects' }).to be_configured
        end
      end
    end
  end

  # mesh keeps its terms in the same tables as a staff vocabulary, but a MeSH import
  # replaces all of them, so Qa::Authorities::Mesh reports locally_owned? false and
  # the catalog files it separately.
  describe 'a vocabulary holding an imported copy' do
    it 'is listed as cached, awaiting its import task' do
      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(entry.origin).to eq :cached
      expect(entry).to be_cached
      expect(entry.term_count).to eq 0
      expect(entry).to be_awaiting_import
      expect(entry.import_task).to eq 'mesh:import_tenant'
    end

    # Its terms are not staff's to change, whether or not they are imported yet.
    it 'is never editable' do
      Qa::LocalAuthority.create!(name: 'mesh')
                        .local_authority_entries.create!(label: 'Diabetes', uri: 'mesh:diabetes')

      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(entry).not_to be_editable
      expect(entry).to be_stored_locally
    end

    # Read-only, but worth opening: a depositor needs to look up the term id.
    it 'is viewable once its terms are imported' do
      Qa::LocalAuthority.create!(name: 'mesh')
                        .local_authority_entries.create!(label: 'Diabetes', uri: 'mesh:diabetes')

      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(entry).to be_viewable
    end

    it 'is not viewable before then, because there is nothing to show' do
      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(entry).not_to be_viewable
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
