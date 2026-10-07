# frozen_string_literal: true

RSpec.describe Hyku::Mods::MappingPath do
  def steps_for(mapping)
    described_class.parse(mapping).steps.map(&:to_h)
  end

  it 'parses nested steps' do
    expect(steps_for('mods:originInfo/mods:dateCreated')).to eq [
      { name: 'originInfo', attributes: {}, children: [] },
      { name: 'dateCreated', attributes: {}, children: [] }
    ]
  end

  it 'parses attribute predicates in either quote style' do
    expect(steps_for(%(mods:relatedItem[@type="host"][@displayLabel='Collection']/mods:titleInfo/mods:title)).first)
      .to eq(name: 'relatedItem', attributes: { 'type' => 'host', 'displayLabel' => 'Collection' }, children: [])
  end

  it 'parses a child-value predicate into a fixed child element' do
    expect(steps_for(%(mods:name[mods:role/mods:roleTerm="creator"]/mods:namePart)).first)
      .to eq(name: 'name', attributes: {}, children: [{ path: %w[role roleTerm], text: 'creator' }])
  end

  describe '#schema_error' do
    {
      'mods:originInfo/mods:sequence' => /sequence': This element is not expected/,
      'mods:name/mods:role' => /role': Character content other than whitespace is not allowed/,
      'mods:titleInfo[@lang="eng"][@bogus="x"]/mods:title' => /attribute 'bogus': The attribute 'bogus' is not allowed/,
      'mods:location/mods:url[@access="bogus"]' => /attribute 'access': \[facet 'enumeration'\]/
    }.each do |mapping, objection|
      it "objects to #{mapping}" do
        expect(described_class.parse(mapping).schema_error).to match(objection)
      end
    end

    [
      %(mods:name[mods:role/mods:roleTerm="creator"]/mods:namePart),
      'mods:originInfo/mods:dateCreated[@encoding="w3cdtf"]',
      'mods:physicalDescription/mods:digitalOrigin',
      'mods:part/mods:extent/mods:total'
    ].each do |mapping|
      it "accepts #{mapping}, whatever its value" do
        expect(described_class.parse(mapping).schema_error).to be_nil
      end
    end
  end

  [
    %(modstitleInfo[@type="alternative"]/mods:title),
    'mods:originInfo/place/placeTerm',
    %(mods:location/mods:url[access="object in context"]),
    %(mods:name[mods:role/mods:roleTerm[contains(.,'Creator')]]/mods:namePart),
    'mods:abstract/',
    ''
  ].each do |mapping|
    it "rejects #{mapping.inspect}" do
      expect { described_class.parse(mapping) }.to raise_error(described_class::InvalidPath, /Unsupported MODS mapping/)
    end
  end
end
