# frozen_string_literal: true

RSpec.describe Hyku::FlexibleSchemaValidators::ModsMappingValidator do
  subject(:validator) { described_class.new(context) }
  let(:context) { Hyrax::FlexibleSchemaValidators::ValidationContext.new(profile:) }
  let(:warnings) { validator.tap(&:validate!).violations.map(&:message) }
  let(:profile) { { 'properties' => { 'creator' => { 'mappings' => { 'mods_oai_pmh' => mapping } } } } }

  context 'with a supported mapping to a MODS element' do
    let(:mapping) { %(mods:name[mods:role/mods:roleTerm="creator"]/mods:namePart) }

    it 'does not warn' do
      expect(warnings).to be_empty
    end
  end

  context 'with a mapping the builder cannot parse' do
    let(:mapping) { %(mods:name[mods:role/mods:roleTerm[contains(.,'Creator')]]/mods:namePart) }

    it 'warns, naming the property and the mapping' do
      expect(warnings).to contain_exactly(a_string_including('`creator`', "contains(.,'Creator')", 'leave the property out'))
    end
  end

  context 'with a mapping to an element MODS does not have' do
    let(:mapping) { 'mods:sequence' }

    it 'warns, naming the element' do
      expect(warnings).to contain_exactly(a_string_including('`creator`', '`sequence` is not a top-level MODS element'))
    end
  end

  context 'with mappings that are not a hash' do
    let(:profile) { { 'properties' => { 'creator' => { 'mappings' => 'mods:name/mods:namePart' } } } }

    it 'leaves the shape to the profile schema validator rather than raising' do
      expect(warnings).to be_empty
    end
  end

  context 'with a nested element MODS does not allow there' do
    let(:mapping) { 'mods:originInfo/mods:sequence' }

    it 'warns with the schema objection' do
      expect(warnings).to contain_exactly(a_string_including('`creator`', 'does not fit the MODS 3.7 schema',
                                                             "Element 'sequence': This element is not expected"))
    end
  end

  context 'with no MODS mapping' do
    let(:profile) { { 'properties' => { 'creator' => { 'mappings' => { 'simple_dc_pmh' => 'dc:creator' } } } } }

    it 'does not warn' do
      expect(warnings).to be_empty
    end
  end

  it 'runs when a profile is validated' do
    profile = YAML.load_file(Rails.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml'))
    profile['properties']['title']['mappings']['mods_oai_pmh'] = 'mods:sequence'
    service = Hyrax::FlexibleSchemaValidatorService.new(profile:).tap(&:validate!)

    expect(service.warnings).to include(a_string_including('`sequence` is not a top-level MODS element'))
  end
end
