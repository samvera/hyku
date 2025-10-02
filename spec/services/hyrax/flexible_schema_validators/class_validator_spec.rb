# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::ClassValidator do
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

  describe '#validate_availability!' do
    let(:profile) do
      {
        'classes' => {
          'GenericWorkResource' => { 'display_label' => 'Generic Work' },
          'InvalidWorkType' => { 'display_label' => 'Invalid Work' }
        },
        'properties' => {
          'title' => {
            'available_on' => {
              'class' => ['AnotherInvalidWorkType']
            }
          }
        }
      }
    end

    before do
      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork'])
    end

    it 'adds error for invalid classes in profile classes' do
      validator.validate_availability!
      expect(errors.first).to include('InvalidWorkType')
    end

    it 'adds error for invalid classes in available_on' do
      validator.validate_availability!
      expect(errors.first).to include('AnotherInvalidWorkType')
    end

    it 'combines all invalid classes in one error message' do
      validator.validate_availability!
      expect(errors.first).to eq('Invalid classes: InvalidWorkType, AnotherInvalidWorkType.')
    end

    it 'does not add error when all classes are valid' do
      profile['classes'].delete('InvalidWorkType')
      profile['properties']['title']['available_on']['class'] = ['GenericWorkResource']

      validator.validate_availability!
      expect(errors).to be_empty
    end

    it 'handles nil properties' do
      profile['classes'].delete('InvalidWorkType')
      profile['properties'] = nil
      validator.validate_availability!
      expect(errors).to be_empty
    end

    it 'strips Resource suffix when checking against registered types' do
      profile['classes'] = { 'GenericWorkResource' => { 'display_label' => 'Generic Work' } }
      profile['properties'] = {}

      validator.validate_availability!
      expect(errors).to be_empty
    end

    it 'excludes required classes from validation' do
      profile['classes'] = { 'AdminSetResource' => { 'display_label' => 'Admin Set' } }
      profile['properties'] = {}

      validator.validate_availability!
      expect(errors).to be_empty
    end
  end

  describe '#validate_references!' do
    let(:profile) do
      {
        'classes' => {
          'GenericWorkResource' => { 'display_label' => 'Generic Work' }
        },
        'properties' => {
          'title' => {
            'available_on' => {
              'class' => ['GenericWorkResource', 'UndefinedClass']
            }
          },
          'creator' => {
            'available_on' => {
              'class' => ['AnotherUndefinedClass']
            }
          }
        }
      }
    end

    it 'adds error for undefined classes' do
      validator.validate_references!
      expect(errors).to include('Classes referenced in `available_on` but not defined in `classes`: UndefinedClass, AnotherUndefinedClass.')
    end

    it 'does not add error when all referenced classes are defined' do
      profile['classes']['UndefinedClass'] = { 'display_label' => 'Undefined' }
      profile['classes']['AnotherUndefinedClass'] = { 'display_label' => 'Another Undefined' }

      validator.validate_references!
      expect(errors).to be_empty
    end

    it 'handles empty properties' do
      profile['properties'] = {}

      validator.validate_references!
      expect(errors).to be_empty
    end

    it 'handles nil properties' do
      profile['properties'] = nil

      validator.validate_references!
      expect(errors).to be_empty
    end
  end

  describe '#validate_existing_records!' do
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

      validator.validate_existing_records!
      expect(errors).to include('Classes with existing records cannot be removed from the profile: ImageResource.')
    end

    it 'does not add error when no classes have existing records' do
      validator.validate_existing_records!
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

      validator.validate_existing_records!
    end

    it 'handles counterpart classes correctly' do
      profile['classes']['Image'] = { 'display_label' => 'Image' }

      validator.validate_existing_records!
      expect(errors).to be_empty
    end

    it 'logs error when query service fails' do
      allow(Hyrax.query_service).to receive(:count_all_of_model)
        .with(model: ImageResource).and_raise(StandardError, 'Database error')
      allow(Rails.logger).to receive(:error)

      validator.validate_existing_records!
      expect(Rails.logger).to have_received(:error).with('Error checking records for ImageResource: Database error')
    end

    it 'skips classes that cannot be resolved' do
      allow(validator).to receive(:resolve_model_class).and_return(nil)

      validator.validate_existing_records!
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
