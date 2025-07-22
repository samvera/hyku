# frozen_string_literal: true

RSpec.describe Hyrax::CoreMetadataValidator do
  subject(:service) { described_class.new(profile: profile, errors: errors) }
  let(:profile) { YAML.safe_load_file(yaml) }
  let(:yaml) { Rails.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml').to_s }
  let(:errors) { [] }

  describe '#validate!' do
    before { service.validate! }

    context 'with a valid schema' do
      it 'does not have any errors' do
        expect(errors).to be_empty
      end
    end

    context 'when core metadata properties are misconfigured' do
      context 'when a required property is missing' do
        before do
          profile['properties'].delete('depositor')
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include('Missing required property: depositor.')
        end
      end

      context 'when data_type is incorrect' do
        before do
          profile['properties']['title']['data_type'] = nil
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include("Property 'title' must have data_type set to 'array'.")
        end
      end

      context 'when indexing is missing keys' do
        before do
          profile['properties']['depositor']['indexing'] = ['depositor_tesim']
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include("Property 'depositor' is missing required indexing: depositor_ssim.")
        end
      end

      context 'when predicate (property_uri) is incorrect' do
        before do
          profile['properties']['title']['property_uri'] = 'http://example.com/wrong-predicate'
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include("Property 'title' must have property_uri set to http://purl.org/dc/terms/title.")
        end
      end

      context 'when a property is not available on all classes' do
        before do
          # The full list of classes for title is:
          # - AdminSetResource
          # - CollectionResource
          # - Hyrax::FileSet
          # - GenericWorkResource
          # - ImageResource
          # - EtdResource
          # - OerResource
          # Popping the last one off for this test.
          profile['properties']['title']['available_on']['class'].pop
          service.validate!
        end

        it 'is invalid' do
          expect(errors).to include("Property 'title' must be available on all classes, but is missing from: OerResource.")
        end
      end

      context 'when title is not required' do
        context 'because `cardinality.minimum` is 0' do
          before do
            profile['properties']['title']['cardinality']['minimum'] = '0'
            service.validate!
          end

          it 'is invalid' do
            expect(errors).to include("Property 'title' must have a cardinality minimum of at least 1.")
          end
        end

        context 'because `cardinality` is missing' do
          before do
            profile['properties']['title'].delete('cardinality')
            service.validate!
          end

          it 'is invalid' do
            expect(errors).to include("Property 'title' must have a cardinality minimum of at least 1.")
          end
        end
      end
    end
  end
end
