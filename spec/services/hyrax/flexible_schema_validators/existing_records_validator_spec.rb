# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::ExistingRecordsValidator do
  subject(:validator) { described_class.new(profile, required_classes, errors) }

  let(:profile) { {} }
  let(:required_classes) { ['AdminSetResource', 'CollectionResource', 'Hyrax::FileSet'] }
  let(:errors) { [] }

  describe '#initialize' do
    it 'sets instance variables' do
      expect(validator.instance_variable_get(:@profile)).to eq(profile)
      expect(validator.instance_variable_get(:@required_classes)).to eq(required_classes)
      expect(validator.instance_variable_get(:@errors)).to eq(errors)
    end
  end

  describe '#validate!' do
    let(:profile) do
      {
        'classes' => {
          'GenericWorkResource' => { 'display_label' => 'Generic Work' }
        },
        'properties' => {}
      }
    end

    before do
      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image'])
      allow(Hyrax.query_service).to receive(:count_all_of_model).and_return(0)
    end

    it 'adds error for classes with existing records' do
      allow(Hyrax.query_service).to receive(:count_all_of_model)
        .with(model: ImageResource).and_return(1)

      validator.validate!
      expect(errors).to include('Classes with existing records cannot be removed from the profile: ImageResource.')
    end

    it 'does not add error when no classes have existing records' do
      validator.validate!
      expect(errors).to be_empty
    end

    it 'queries for a model only once, even with aliases' do
      stub_const('Image', Class.new)
      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['Image'])
      profile['classes'] = {}

      expect(Hyrax.query_service).to receive(:count_all_of_model).with(model: Image).once.and_return(0)
      expect(Hyrax.query_service).to receive(:count_all_of_model).with(model: AdminSetResource).once.and_return(0)
      expect(Hyrax.query_service).to receive(:count_all_of_model).with(model: CollectionResource).once.and_return(0)
      expect(Hyrax.query_service).to receive(:count_all_of_model).with(model: Hyrax::FileSet).once.and_return(0)

      validator.validate!
    end

    context 'with counterpart classes' do
      before do
        stub_const('ImageResource', Class.new) unless defined?(ImageResource)
        stub_const('Image', ImageResource) unless defined?(Image) # Alias Image to ImageResource for the test
      end

      it 'adds an error if a class with records is removed, even if its counterpart is present' do
        profile['classes'] = { 'Image' => { 'display_label' => 'Image' } }
        allow(Hyrax.query_service).to receive(:count_all_of_model).with(model: ImageResource).and_return(1)

        validator.validate!
        expect(errors).to include('Classes with existing records cannot be removed from the profile: ImageResource.')
      end

      it 'does not add an error if a class without a Resource suffix is present' do
        profile['classes'] = { 'Image' => { 'display_label' => 'Image' } }
        allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['Image'])

        validator.validate!
        expect(errors).to be_empty
      end
    end

    it 'logs error when query service fails' do
      allow(Hyrax.query_service).to receive(:count_all_of_model)
        .with(model: ImageResource).and_raise(StandardError, 'Database error')
      allow(Rails.logger).to receive(:error)

      validator.validate!
      expect(Rails.logger).to have_received(:error).with('Error checking records for ImageResource: Database error')
    end

    it 'skips classes that cannot be resolved' do
      allow(validator).to receive(:resolve_model_class).and_return(nil)

      validator.validate!
      expect(errors).to be_empty
    end
  end

  describe '#potential_existing_classes' do
    it 'includes required classes' do
      expect(validator.send(:potential_existing_classes)).to include(*required_classes)
    end

    it 'includes registered curation concern types' do
      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image'])

      classes = validator.send(:potential_existing_classes)
      expect(classes).to include('GenericWork', 'GenericWorkResource', 'Image', 'ImageResource')
    end

    it 'removes duplicates' do
      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork'])

      classes = validator.send(:potential_existing_classes)
      expect(classes.uniq).to eq(classes)
    end
  end

  describe '#resolve_model_class' do
    context 'with configured models' do
      {
        'Hyrax::FileSet' => :file_set_model,
        'Hyrax::AdminSet' => :admin_set_model,
        'Hyrax::Collection' => :collection_model
      }.each do |class_name, config_key|
        it "resolves #{class_name} using #{config_key}" do
          model = stub_const(class_name, Class.new)
          allow(Hyrax.config).to receive(config_key).and_return(class_name)

          result = validator.send(:resolve_model_class, class_name)
          expect(result).to eq(model)
        end
      end
    end

    it 'resolves class name directly' do
      stub_const('GenericWorkResource', Class.new)

      result = validator.send(:resolve_model_class, 'GenericWorkResource')
      expect(result).to eq(GenericWorkResource)
    end

    it 'falls back to base name when direct resolution fails' do
      stub_const('TestWork', Class.new)

      # Test with a class name that doesn't exist directly but has a base name that does
      result = validator.send(:resolve_model_class, 'TestWorkResource')
      expect(result).to eq(TestWork)
    end

    it 'returns nil when both direct and base name resolution fail' do
      allow(Rails.logger).to receive(:warn)

      result = validator.send(:resolve_model_class, 'InvalidClass')
      expect(result).to be_nil
      expect(Rails.logger).to have_received(:warn).with('Could not resolve model class for: InvalidClass')
    end
  end
end
