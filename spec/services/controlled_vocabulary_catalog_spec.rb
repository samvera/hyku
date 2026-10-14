# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ControlledVocabularyCatalog do
  # The suite seeds every real yaml vocabulary into the tables, so an unstubbed
  # file_based_names would be entirely claimed by database rows. Naming a fictional
  # file set keeps these examples independent of that seed state.
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

    # Sorting reads the label, so an authority that resolves without one must not
    # take the whole page down with it.
    it 'lists an authority whose label cannot be determined' do
      allow(described_class).to receive(:remote)
        .and_return([described_class::Entry.new(source_key: 'nameless', origin: :remote)])

      expect(described_class.all.map(&:source_key)).to include 'nameless'
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
    it 'is editable before it has any terms' do
      Qa::LocalAuthority.create!(name: 'lab_names', label: 'Lab Names')

      entry = described_class.database.detect { |e| e.source_key == 'lab_names' }

      expect(entry.term_count).to eq 0
      expect(entry).to be_editable
      expect(entry).to be_listable
    end
  end

  describe '.terms_for' do
    let(:vocabulary) { Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms') }

    it 'reads the terms a database row holds' do
      vocabulary.local_authority_entries.create!(label: 'Special Collections', uri: 'special-collections')
      entry = described_class.database.detect { |e| e.source_key == 'reading_rooms' }

      expect(described_class.terms_for(entry).first)
        .to include('id' => 'special-collections', 'label' => 'Special Collections', 'active' => true)
    end

    it 'returns nothing for an imported copy, which holds too many terms to list' do
      mesh = Qa::LocalAuthority.create!(name: 'mesh')
      mesh.local_authority_entries.create!(label: 'Diabetes', uri: 'mesh:diabetes')
      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(described_class.terms_for(entry)).to be_nil
    end

    # A vocabulary can hold tens of thousands of terms, so the page caps the list.
    # The cap has to be visible to the caller, or a reader concludes a term is absent.
    it 'stops at the term limit' do
      stub_const("#{described_class}::TERM_LIMIT", 2)
      3.times { |i| vocabulary.local_authority_entries.create!(label: "Room #{i}", uri: "room-#{i}") }
      entry = described_class.database.detect { |e| e.source_key == 'reading_rooms' }

      expect(described_class.terms_for(entry).size).to eq 2
      expect(entry.term_count).to eq 3
    end

    it 'returns nothing for a remote service, which cannot be enumerated' do
      entry = described_class.remote.detect { |e| e.source_key == 'loc/subjects' }

      expect(described_class.terms_for(entry)).to be_nil
    end

    # nil and [] are different answers: nil is "cannot say", [] is "nothing here".
    # A page that collapses them tells a reader an unreadable vocabulary is empty.
    it 'distinguishes a yaml file it cannot read from one with no terms' do
      allow(Qa::Authorities::Local).to receive(:subauthority_for)
        .with('geo_regions').and_raise(Qa::InvalidSubAuthority, 'missing')
      unreadable = described_class.file_based.detect { |e| e.source_key == 'geo_regions' }

      expect(described_class.terms_for(unreadable)).to be_nil
    end

    it 'reports an empty database vocabulary as empty, not unreadable' do
      Qa::LocalAuthority.create!(name: 'lab_names')
      entry = described_class.database.detect { |e| e.source_key == 'lab_names' }

      expect(described_class.terms_for(entry)).to eq []
    end
  end

  describe '.find!' do
    it 'finds a database vocabulary' do
      Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms')

      expect(described_class.find!('reading_rooms').origin).to eq :database
    end

    it 'finds a remote authority' do
      expect(described_class.find!('loc/subjects').origin).to eq :remote
    end

    it 'raises for a key no authority answers to' do
      expect { described_class.find!('not_a_vocabulary') }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    # A profile written before the dashboard advertised the camelCase spelling can
    # still deposit against the field, so its page has to open too.
    it 'resolves a legacy spelling to the vocabulary it names' do
      entry = described_class.find!('loc/genre_forms')

      expect(entry.source_key).to eq 'loc/genreForms'
    end

    # A miss used to fall through to .all, which builds the database list again on
    # top of the one already searched.
    it 'builds the database list once when it has to fall through' do
      allow(described_class).to receive(:database).and_call_original

      described_class.find!('loc/subjects')

      expect(described_class).to have_received(:database).once
    end

    # Resolving through an alias searches a second time, once per spelling tried.
    # Bounded by how many spellings remote_authorities gives one url, and reached
    # only by a profile citing a legacy key.
    it 'searches once per spelling when it resolves through an alias' do
      allow(described_class).to receive(:database).and_call_original

      described_class.find!('loc/genre_forms')

      expect(described_class).to have_received(:database).twice
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

    # The service holds the terms and is searched as staff type, so the page says
    # that rather than showing an empty list.
    it 'has a page, but no term list to show on it' do
      entry = described_class.remote.detect { |e| e.source_key == 'loc/subjects' }

      expect(entry).not_to be_listable
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

    # Read through the account's accessors, not Site.account.settings and not
    # Qa::Authorities::Geonames.username. The hash skips the environment fallbacks
    # the reader applies, and the qa class attribute holds whichever tenant
    # configured Hyrax last in this process.
    context 'with a tenant' do
      let(:account) do
        instance_double(Account, geonames_username: geonames, discogs_user_token: discogs)
      end

      let(:discogs) { '' }

      before { allow(Site).to receive(:account).and_return(account) }

      context 'whose credentials are set' do
        let(:geonames) { 'qrtfhx' }

        it 'does not flag the service' do
          expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).to be_configured
        end
      end

      context 'whose credentials are missing' do
        let(:geonames) { '' }

        it 'flags the service' do
          expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).not_to be_configured
        end

        it 'leaves a service that needs no credentials alone' do
          expect(described_class.remote.detect { |e| e.source_key == 'loc/subjects' }).to be_configured
        end
      end

      # The reader returns whatever the HYKU_/HYRAX_ fallback supplies, so a
      # credential set only in the environment still counts as configured.
      context 'whose credentials come from the environment' do
        let(:geonames) { 'zmbvkp' }

        it 'does not flag the service' do
          expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).to be_configured
        end
      end
    end

    # A tenant whose settings have never been written must not read as configured:
    # the credential is genuinely absent.
    context 'with a tenant that has no settings' do
      before do
        allow(Site).to receive(:account)
          .and_return(instance_double(Account, geonames_username: nil, discogs_user_token: nil))
      end

      it 'flags the services that need credentials' do
        expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).not_to be_configured
        expect(described_class.remote.detect { |e| e.provider == 'discogs' }).not_to be_configured
      end
    end

    context 'with no tenant at all' do
      before { allow(Site).to receive(:account).and_return(nil) }

      it 'flags the services that need credentials' do
        expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).not_to be_configured
      end
    end

    # An unanswerable check is not an answer of "configured". Reporting ready on a
    # failed lookup sends staff to debug a form that was never going to work.
    context 'when the credential check itself fails' do
      before do
        account = instance_double(Account)
        allow(account).to receive(:geonames_username).and_raise(StandardError, 'settings unreadable')
        allow(account).to receive(:discogs_user_token).and_return('')
        allow(Site).to receive(:account).and_return(account)
      end

      it 'flags the service rather than reporting it ready' do
        expect(described_class.remote.detect { |e| e.source_key == 'geonames' }).not_to be_configured
      end
    end
  end

  # mesh keeps its terms in the same tables as a staff vocabulary, but a MeSH import
  # replaces all of them, so Qa::Authorities::Mesh reports locally_owned? false and
  # the catalog files it separately.
  describe 'a vocabulary holding an imported copy' do
    # The locale names it, so importing must not rename it: display_label alone would
    # titleize the source key and turn "MeSH" into "Mesh".
    it 'keeps its name once imported' do
      Qa::LocalAuthority.create!(name: 'mesh')

      expect(described_class.database.detect { |e| e.source_key == 'mesh' }.label).to eq 'MeSH'
    end

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
      expect(entry).to be_cached
    end

    # A MeSH release runs to about 30,000 terms, so the list is not offered — but the
    # page still is, because it says where the vocabulary is used.
    it 'has a page but no term list, imported or not' do
      Qa::LocalAuthority.create!(name: 'mesh')
                        .local_authority_entries.create!(label: 'Diabetes', uri: 'mesh:diabetes')

      entry = described_class.database.detect { |e| e.source_key == 'mesh' }

      expect(entry).not_to be_listable
      expect(described_class.terms_for(entry)).to be_nil
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
