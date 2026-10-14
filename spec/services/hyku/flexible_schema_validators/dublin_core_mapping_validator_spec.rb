# frozen_string_literal: true

RSpec.describe Hyku::FlexibleSchemaValidators::DublinCoreMappingValidator do
  subject(:validator) { described_class.new(context) }
  let(:context) { Hyrax::FlexibleSchemaValidators::ValidationContext.new(profile:) }
  let(:warnings) { validator.tap(&:validate!).violations.map(&:message) }
  let(:profile) { { 'properties' => { 'subject' => { 'mappings' => { 'simple_dc_pmh' => mapping } } } } }

  context 'with a Dublin Core element' do
    let(:mapping) { 'dc:subject' }

    it 'does not warn' do
      expect(warnings).to be_empty
    end
  end

  context 'with something other than a Dublin Core element' do
    let(:mapping) { 'dc:keyword' }

    it 'warns, naming the property and the mapping' do
      expect(warnings).to contain_exactly(a_string_including('`subject`', '`dc:keyword`', 'not one of the fifteen Dublin Core elements'))
    end
  end

  context 'with mappings that are not a hash' do
    let(:profile) { { 'properties' => { 'subject' => { 'mappings' => 'dc:subject' } } } }

    it 'leaves the shape to the profile schema validator rather than raising' do
      expect(warnings).to be_empty
    end
  end

  it 'runs when a profile is validated' do
    profile = YAML.load_file(Rails.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml'))
    profile['properties']['title']['mappings']['simple_dc_pmh'] = 'dc:headline'
    service = Hyrax::FlexibleSchemaValidatorService.new(profile:).tap(&:validate!)

    expect(service.warnings).to include(a_string_including('`dc:headline`', 'not one of the fifteen Dublin Core elements'))
  end
end
