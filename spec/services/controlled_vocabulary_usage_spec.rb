# frozen_string_literal: true

RSpec.describe ControlledVocabularyUsage do
  let(:profile) do
    {
      'classes' => {
        'GenericWorkResource' => { 'display_label' => 'Generic Work' },
        'ImageResource' => { 'display_label' => 'Image' },
        'Hyrax::FileSet' => { 'display_label' => 'File Set' }
      },
      'properties' => {
        'license' => {
          'available_on' => { 'class' => ['GenericWorkResource', 'ImageResource', 'Hyrax::FileSet'] },
          'controlled_values' => { 'sources' => ['licenses'] },
          'display_label' => { 'default' => 'blacklight.search.fields.index.license_tesim' }
        },
        'rights_statement' => {
          'available_on' => { 'class' => ['GenericWorkResource'] },
          # A second source on the same property, and whitespace a shipped
          # profile has been seen to carry.
          'controlled_values' => { 'sources' => [' licenses', 'rights_statements'] },
          'display_label' => { 'default' => 'Rights Statement' }
        },
        'creator' => {
          'available_on' => { 'class' => ['GenericWorkResource'] },
          'controlled_values' => { 'sources' => ['null'] }
        },
        # Its authority is hardcoded in the form partial, so the profile declares no
        # source. It is still controlled, and the profile is where the work types
        # come from.
        'based_near' => {
          'available_on' => { 'class' => ['GenericWorkResource', 'ImageResource'] },
          'controlled_values' => { 'sources' => ['null'] }
        }
      }
    }
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(profile)
  end

  describe '.citing' do
    it 'returns every property citing the vocabulary' do
      expect(described_class.citing('licenses').map(&:name)).to eq %w[license rights_statement]
    end

    it 'reads the profile once' do
      described_class.citing('licenses')

      expect(Hyrax::FlexibleSchema).to have_received(:current_version).once
    end

    # The based_near partial hardcodes the geonames autocomplete, so the profile
    # never names it as a source. Reading only controlled_values would report the
    # service unused on a tenant whose deposit form offers it on every work type.
    context 'a vocabulary a form partial reads directly' do
      it 'reports the property the partial controls' do
        expect(described_class.citing('geonames').map(&:name)).to eq %w[based_near]
      end

      it 'takes its work types from the profile' do
        work_types = described_class.citing('geonames').first.work_types

        expect(work_types.map(&:name)).to eq %w[GenericWorkResource ImageResource]
      end

      it 'is unused when the profile does not offer the property at all' do
        profile['properties'].delete('based_near')

        expect(described_class.citing('geonames')).to eq []
      end
    end

    it 'labels each work type from its class name, keeping the class itself' do
      work_types = described_class.citing('licenses').first.work_types

      expect(work_types.map(&:label)).to eq ['Generic Work', 'Image', 'File Set']
      expect(work_types.map(&:name)).to eq ['GenericWorkResource', 'ImageResource', 'Hyrax::FileSet']
    end

    it 'keeps the work type list per property' do
      rights = described_class.citing('licenses').last

      expect(rights.work_types.map(&:name)).to eq ['GenericWorkResource']
    end

    it 'finds a property through a second source' do
      expect(described_class.citing('rights_statements').map(&:name)).to eq ['rights_statement']
    end

    it 'returns an empty array when no property cites the vocabulary' do
      expect(described_class.citing('subjects')).to eq []
    end

    # The dashboard resolves `loc/genre_forms` to the entry keyed `loc/genreForms`,
    # then asks for that key's usage — so a profile citing the older spelling has to
    # be found under either one, or its page reports the vocabulary unused.
    it 'finds a property citing another spelling of the same vocabulary' do
      profile['properties']['genre'] = {
        'available_on' => { 'class' => ['GenericWorkResource'] },
        'controlled_values' => { 'sources' => ['loc/genre_forms'] }
      }

      expect(described_class.citing('loc/genreForms').map(&:name)).to eq ['genre']
    end

    # Some shipped profiles label CollectionResource "pcdmcollection"; the class
    # name is what is stable, so profile labels are ignored altogether.
    it 'ignores the profile display_label for work types' do
      profile['classes']['CollectionResource'] = { 'display_label' => 'pcdmcollection' }
      profile['properties']['license']['available_on']['class'] << 'CollectionResource'

      labels = described_class.citing('licenses').first.work_types.map(&:label)

      expect(labels).to include 'Collection'
      expect(labels).not_to include 'pcdmcollection'
    end

    it 'returns nil when the tenant has no profile yet' do
      allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(nil)

      expect(described_class.citing('licenses')).to be_nil
    end

    context 'when flexible metadata is off' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

      it 'answers from the form mapping instead of a profile' do
        properties = described_class.citing('licenses')

        expect(properties.map(&:name)).to eq ['license']
        expect(Hyrax::FlexibleSchema).not_to have_received(:current_version)
      end

      it 'lists the work types whose model defines the property' do
        names = described_class.citing('licenses').first.work_types.map(&:name)

        expect(names).to include 'GenericWorkResource'
        expect(names).not_to include 'GenericWork'
      end

      it 'labels the work types without the Valkyrie suffix' do
        labels = described_class.citing('licenses').first.work_types.map(&:label)

        expect(labels).to include 'Generic Work'
        expect(labels).to include 'ETD'
      end

      # The OER form reads resource_type from oer_types through its own partial,
      # not the generic mapping, so the vocabulary must not read as unused.
      it 'reports a vocabulary a form partial reads outside the mapping' do
        properties = described_class.citing('oer_types')

        expect(properties.map(&:name)).to eq ['resource_type']
        expect(properties.first.work_types.map(&:name)).to eq ['OerResource']
      end

      it 'returns an empty array for a vocabulary the mapping does not cite' do
        expect(described_class.citing('reading_rooms')).to eq []
      end
    end
  end
end
