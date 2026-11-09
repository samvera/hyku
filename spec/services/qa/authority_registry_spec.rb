# frozen_string_literal: true

require 'rails_helper'

# Asserts what the qa gem reports about itself, with no Hyku fixtures, so these
# examples travel with the class if it is ever contributed upstream.
RSpec.describe Qa::AuthorityRegistry do
  describe '.remote_services' do
    subject(:services) { described_class.remote_services }

    it 'finds the external services the gem provides' do
      expect(services.keys).to include('loc', 'getty', 'geonames', 'fast', 'discogs')
    end

    it 'maps each key to its authority class' do
      expect(services['getty']).to eq Qa::Authorities::Getty
    end

    # The class is AssignFast, but the vocabulary is cited as fast/*.
    it 'uses the source key a profile cites, not the class name' do
      expect(services.keys).to include 'fast'
      expect(services.keys).not_to include 'assign_fast'
    end

    it 'excludes the local backend' do
      expect(services.keys).not_to include 'local'
    end

    it 'excludes abstract base classes' do
      expect(services.keys).not_to include('base', 'web_service_base')
    end

    # Hyrax adds authorities for picking works and collections, and Hyku adds its
    # own local classes. Neither is an external vocabulary, and both are excluded by
    # where they are defined rather than by name.
    it 'excludes authorities a host application defines' do
      expect(services.keys).not_to include('collections', 'find_works', 'compound_works', 'local_vocabulary', 'mesh')
    end

    it 'excludes the subauthority mixins' do
      expect(services.keys.grep(/subauthority/)).to be_empty
    end

    # Building the list loads and locates every constant under Qa::Authorities, and
    # the index page asks for it once per remote vocabulary. What the gem provides
    # cannot change while the process runs, so the walk happens once.
    it 'walks the gem once' do
      described_class.remote_services
      allow(Qa::Authorities).to receive(:constants).and_call_original

      described_class.remote_services

      expect(Qa::Authorities).not_to have_received(:constants)
    end

    # Qa::Authorities::Oclcts reads config/oclcts-authorities.yml when it loads, so
    # a host without that file must still get the rest of the list.
    it 'skips an authority that cannot be loaded' do
      expect(services.keys).to include('loc')
    end
  end

  describe '.subauthorities_of' do
    it 'lists the vocabularies a multi-vocabulary service offers' do
      expect(described_class.subauthorities_of(Qa::Authorities::Getty)).to contain_exactly('aat', 'tgn', 'ulan')
    end

    # A single-vocabulary service is cited by its own key alone, with nothing after
    # the slash, so nil stands in for the missing subauthority.
    it 'yields a single nil for a service with no subauthorities' do
      expect(described_class.subauthorities_of(Qa::Authorities::Geonames)).to eq [nil]
    end
  end

  describe '.vocabularies_for' do
    it 'builds the keys a profile cites' do
      expect(described_class.vocabularies_for('getty', Qa::Authorities::Getty))
        .to contain_exactly('getty/aat', 'getty/tgn', 'getty/ulan')
    end

    it 'omits the slash for a single-vocabulary service' do
      expect(described_class.vocabularies_for('geonames', Qa::Authorities::Geonames)).to eq ['geonames']
    end

    # qa spells this one in camelCase, and subauthority_for rejects genre_forms.
    it 'keeps the spelling qa resolves' do
      keys = described_class.vocabularies_for('loc', Qa::Authorities::Loc)

      expect(keys).to include 'loc/genreForms'
      expect(keys).not_to include 'loc/genre_forms'
    end
  end

  describe '.display_name' do
    it 'spells out an acronym' do
      expect(described_class.display_name('aat')).to eq 'Art & Architecture Thesaurus'
    end

    it 'reads a camelCase key as words' do
      expect(described_class.display_name('genreForms')).to eq 'Genre/Form Terms'
    end

    it 'titleizes a key it has no name for' do
      expect(described_class.display_name('countries')).to eq 'Countries'
    end
  end
end
