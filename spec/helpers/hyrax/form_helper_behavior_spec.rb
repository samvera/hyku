# frozen_string_literal: true

RSpec.describe Hyrax::FormHelperBehavior, type: :helper do
  describe '#controlled_vocabulary_source_for' do
    context 'when flexible=false' do
      before do
        allow(Hyrax.config).to receive(:flexible?).and_return(false)
      end

      it 'returns controlled vocabulary service keys' do
        expect(helper.send(:controlled_vocabulary_source_for, :audience)).to eq('audience')
        expect(helper.send(:controlled_vocabulary_source_for, :discipline)).to eq('discipline')
        expect(helper.send(:controlled_vocabulary_source_for, :education_level)).to eq('education_levels')
        expect(helper.send(:controlled_vocabulary_source_for, 'learning_resource_type')).to eq('learning_resource_types')
        expect(helper.send(:controlled_vocabulary_source_for, :license)).to eq('licenses')
        expect(helper.send(:controlled_vocabulary_source_for, :resource_type)).to eq('resource_types')
        expect(helper.send(:controlled_vocabulary_source_for, :rights_statement)).to eq('rights_statements')
      end
    end
  end

  describe '#controlled_vocabulary_service_for' do
    it 'returns the registered service class for a built-in vocabulary' do
      expect(helper.controlled_vocabulary_service_for('licenses')).to eq Hyrax::LicenseService
    end

    context 'with a vocabulary created through the dashboard' do
      before { Qa::LocalAuthority.create!(name: 'reading_rooms') }

      # No entry in the services registry, so without the fallback the field
      # would render as free text instead of a dropdown.
      it 'returns a tolerant service bound to that vocabulary' do
        service = helper.controlled_vocabulary_service_for('reading_rooms')

        expect(service).to be_a Hyrax::TolerantSelectService
        expect(service.authority).to be_a Qa::Authorities::LocalVocabulary
      end

      it 'resolves the source_key a profile cites' do
        vocabulary = Qa::LocalAuthority.find_by(name: 'reading_rooms')

        expect(helper.controlled_vocabulary_service_for(vocabulary.source_key))
          .to be_a Hyrax::TolerantSelectService
      end
    end

    # A deployment can drop a yaml file into config/authorities and cite it in the
    # profile without registering a service class for it. The field still has to
    # render as a dropdown, and a stored value still has to label.
    #
    # Every yaml authority Hyku ships is registered, so the case is set up by
    # withholding the registry entry for one that exists on disk rather than by
    # naming a file that does not: Qa raises InvalidSubAuthority for a name its own
    # registry does not know, whatever this helper believes about it.
    context 'with a yaml vocabulary that has no registered service' do
      before do
        allow(Hyrax::ControlledVocabularies).to receive(:services)
          .and_return(Hyrax::ControlledVocabularies.services.except('licenses'))
      end

      it 'returns a tolerant service bound to that vocabulary' do
        service = helper.controlled_vocabulary_service_for('licenses')

        expect(service).to be_a Hyrax::TolerantSelectService
        expect(service.select_all_options).to be_present
      end
    end

    it 'returns nil for a source no vocabulary of any kind backs' do
      expect(helper.controlled_vocabulary_service_for('nothing_here')).to be_nil
    end
  end

  describe '#controlled_vocabulary_options_for' do
    context 'with a vocabulary created through the dashboard' do
      let!(:vocabulary) { Qa::LocalAuthority.create!(name: 'reading_rooms') }

      before do
        Qa::LocalAuthorityEntry.create!(local_authority: vocabulary,
                                        label: 'Special Collections',
                                        uri: 'https://example.com/special-collections')
        allow(helper).to receive(:controlled_vocabulary_source_for).with(:reading_room).and_return('reading_rooms')
      end

      # Options are [label, uri]: the label is shown, the uri is submitted and
      # stored on the work.
      it 'renders as a select showing labels and submitting uris' do
        config = helper.controlled_vocabulary_options_for(:reading_room)

        expect(config[:type]).to eq 'select'
        expect(config[:options]).to eq [['Special Collections', 'https://example.com/special-collections']]
      end

      it 'withholds a retired term' do
        Qa::LocalAuthorityEntry.create!(local_authority: vocabulary,
                                        label: 'Closed Stacks',
                                        uri: 'https://example.com/closed-stacks',
                                        active: false)

        config = helper.controlled_vocabulary_options_for(:reading_room)

        expect(config[:options].map(&:first)).to eq ['Special Collections']
      end
    end
  end
end
