# frozen_string_literal: true

RSpec.describe 'Default OAI-PMH mappings' do
  let(:metadata_files) { %w[basic_metadata compound_metadata etd_resource oer_resource image_resource] }
  let(:profile_properties) { YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml'))['properties'] }

  def attributes_in(file)
    YAML.load_file(Rails.root.join('config', 'metadata', "#{file}.yaml"))['attributes']
  end

  [Hyku::Mods::MAPPING_KEY].each do |key|
    describe key do
      it 'maps each property a metadata YAML file defines the same way the metadata profile does' do
        metadata_files.each do |file|
          attributes_in(file).each do |property, config|
            next unless profile_properties.key?(property)

            expect(config.dig('mappings', key)).to eq(profile_properties[property].dig('mappings', key)),
                                                   "#{file}.yaml #{property} differs from the profile"
          end
        end
      end

      it 'reaches the schema of a work type when flexible metadata is off' do
        creator = GenericWorkResource.schema.keys.find { |schema_key| schema_key.name == :creator }
        expect(creator.meta.dig('mappings', key)).to eq profile_properties['creator'].dig('mappings', key)
      end
    end
  end

  it 'maps to MODS only in ways MODS records can use' do
    mappings = profile_properties.values + metadata_files.flat_map { |file| attributes_in(file).values }
    mods_mappings = mappings.filter_map { |config| config.dig('mappings', Hyku::Mods::MAPPING_KEY) }.uniq

    expect(mods_mappings.reject { |mapping| Hyku::Mods::MappingPath.cached(mapping) }).to be_empty
  end
end
