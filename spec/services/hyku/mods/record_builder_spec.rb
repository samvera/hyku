# frozen_string_literal: true

RSpec.describe Hyku::Mods::RecordBuilder do
  subject(:xml) { Nokogiri::XML(builder.to_xml) }

  let(:builder) { described_class.new(document, mappings:, item_url:, thumbnail_url: nil) }
  let(:item_url) { 'https://test.example.com/concern/generic_works/abc123' }
  let(:document) do
    SolrDocument.new(
      'id' => 'abc123',
      'title_tesim' => ['A Title', 'A Second Title'],
      'creator_tesim' => ['Smith, Jo', 'Doe, Al'],
      'date_created_tesim' => ['1999'],
      'publisher_tesim' => ['A Press'],
      'subject_tesim' => ['Cats', 'Dogs'],
      'language_tesim' => ['http://id.loc.gov/vocabulary/iso639-2/eng', 'French'],
      'language_label_tesim' => ['English', 'French'],
      'based_near_tesim' => ['http://sws.geonames.org/4049979/'],
      'based_near_label_tesim' => ['Birmingham, Alabama, United States'],
      'license_tesim' => ['http://creativecommons.org/licenses/by/3.0/us/'],
      'license_label_tesim' => ['Attribution 3.0 United States'],
      'resource_link_tesim' => ['https://n2t.net/ark:/87290/abc'],
      'provider_tesim' => ['University of Tennessee'],
      'system_create_dtsi' => '2020-01-01T00:00:00Z'
    )
  end
  let(:mappings) do
    [
      { property: 'creator', mapping: %(mods:name[mods:role/mods:roleTerm="creator"]/mods:namePart),
        index_keys: %w[creator_sim creator_tesim facetable] },
      { property: 'date_created', mapping: 'mods:originInfo/mods:dateCreated', index_keys: ['date_created_tesim'] },
      { property: 'publisher', mapping: 'mods:originInfo/mods:publisher', index_keys: ['publisher_tesim'] },
      { property: 'subject', mapping: 'mods:subject/mods:topic', index_keys: ['subject_tesim'] },
      { property: 'based_near', mapping: 'mods:subject/mods:geographic', index_keys: ['based_near_tesim'] },
      { property: 'language', mapping: 'mods:language/mods:languageTerm', index_keys: ['language_tesim'] },
      { property: 'license', mapping: %(mods:accessCondition[@type="use and reproduction"]),
        index_keys: ['license_tesim'] },
      { property: 'resource_link', mapping: %(mods:location/mods:url[@access="object in context"]),
        index_keys: ['resource_link_tesim'] },
      { property: 'provider', mapping: 'mods:location/mods:physicalLocation', index_keys: ['provider_tesim'] }
    ]
  end
  let(:ns) { Hyku::Mods::ElementTree::NAMESPACE }
  let(:mods_schema) { Hyku::Mods.schema }

  def values_at(path)
    xml.xpath(path, 'm' => ns).map(&:text)
  end

  it 'validates against the MODS 3.7 schema' do
    expect(mods_schema.validate(xml).map(&:message)).to be_empty
  end

  it 'writes a separate name, with its role, for each creator' do
    expect(values_at('/m:mods/m:name/m:namePart')).to eq ['Smith, Jo', 'Doe, Al']
    expect(values_at('/m:mods/m:name/m:role/m:roleTerm')).to eq %w[creator creator]
  end

  it 'shares one wrapper among properties mapped beneath it' do
    expect(xml.xpath('/m:mods/m:originInfo', 'm' => ns).size).to eq 1
    expect(values_at('/m:mods/m:originInfo/*')).to eq ['1999', 'A Press']
  end

  it 'writes each subject heading and each language in a wrapper of its own' do
    expect(xml.xpath('/m:mods/m:subject', 'm' => ns).map { |subject| subject.element_children.size }).to eq [1, 1, 1]
    expect(values_at('/m:mods/m:language/m:languageTerm')).to eq %w[English French]
    expect(xml.xpath('/m:mods/m:language', 'm' => ns).size).to eq 2
  end

  context 'with a mapping to an element MODS does not have' do
    let(:document) { SolrDocument.new('id' => 'abc123', 'sequence_tesim' => ['3']) }
    let(:mappings) { [{ property: 'sequence', mapping: 'mods:sequence', index_keys: ['sequence_tesim'] }] }

    before { Hyku::Mods::MappingPath.cache.clear }

    it 'leaves the property out, so the record stays valid' do
      expect(xml.xpath('/m:mods/m:sequence', 'm' => ns)).to be_empty
      expect(mods_schema.validate(xml).map(&:message)).to be_empty
    end

    it 'warns once' do
      allow(Rails.logger).to receive(:warn)

      2.times { described_class.new(document, mappings:).to_xml }

      expect(Rails.logger).to have_received(:warn).with(/`sequence` is not a top-level MODS element/).once
    end
  end

  context 'with a mapping whose nested element MODS does not allow there' do
    let(:document) { SolrDocument.new('id' => 'abc123', 'sequence_tesim' => ['3']) }
    let(:mappings) { [{ property: 'sequence', mapping: 'mods:originInfo/mods:sequence', index_keys: ['sequence_tesim'] }] }

    before { Hyku::Mods::MappingPath.cache.clear }

    it 'leaves the property out, so the record stays valid' do
      expect(xml.xpath('//m:sequence', 'm' => ns)).to be_empty
      expect(mods_schema.validate(xml).map(&:message)).to be_empty
    end
  end

  context 'with a compound' do
    let(:builder) { described_class.new(document, mappings: [], compounds:) }
    let(:document) do
      SolrDocument.new('id' => 'abc123', 'title_tesim' => ['A Title'],
                       'creators_json_ss' => [{ name: 'Smith, Jo', role: 'Author' }, { name: 'Doe, Al', role: 'Editor' }].to_json)
    end
    let(:compounds) do
      [{ compound: 'creators', subproperties: [
        { key: 'name', property: 'creator_name', mapping: 'mods:name/mods:namePart' },
        { key: 'role', property: 'creator_role', mapping: 'mods:name/mods:role/mods:roleTerm[@type="text"]' }
      ] }]
    end

    it 'writes each entry as one wrapper holding all its sub-properties' do
      names = xml.xpath('/m:mods/m:name', 'm' => ns).map do |name|
        [name.at_xpath('m:namePart', 'm' => ns).text, name.at_xpath('m:role/m:roleTerm[@type="text"]', 'm' => ns).text]
      end

      expect(names).to eq [['Smith, Jo', 'Author'], ['Doe, Al', 'Editor']]
      expect(mods_schema.validate(xml).map(&:message)).to be_empty
    end
  end

  context 'with a compound whose shared wrapper is nested' do
    let(:builder) { described_class.new(document, mappings: [], compounds:) }
    let(:document) do
      SolrDocument.new('id' => 'abc123', 'title_tesim' => ['A Title'],
                       'hosts_json_ss' => [{ name: 'Smith, Jo', role: 'Editor' }].to_json)
    end
    let(:compounds) do
      [{ compound: 'hosts', subproperties: [
        { key: 'name', property: 'host_name', mapping: 'mods:relatedItem/mods:name/mods:namePart' },
        { key: 'role', property: 'host_role', mapping: 'mods:relatedItem/mods:name/mods:role/mods:roleTerm' }
      ] }]
    end

    it 'keeps the entry together at every level' do
      expect(xml.xpath('/m:mods/m:relatedItem/m:name', 'm' => ns).map { |name| name.element_children.map(&:name) })
        .to eq [%w[namePart role]]
    end
  end

  context 'with places of publication' do
    let(:document) { SolrDocument.new('id' => 'abc123', 'publication_place_tesim' => ['Knoxville', 'Nashville']) }
    let(:mappings) do
      [{ property: 'publication_place', mapping: 'mods:originInfo/mods:place/mods:placeTerm',
         index_keys: ['publication_place_tesim'] }]
    end

    it 'writes each in a place of its own' do
      expect(xml.xpath('/m:mods/m:originInfo/m:place', 'm' => ns).map { |place| place.text.strip }).to eq %w[Knoxville Nashville]
    end
  end

  it 'adds the title even when no title mapping is given' do
    expect(values_at('/m:mods/m:titleInfo/m:title')).to eq ['A Title', 'A Second Title']
    expect(xml.xpath('/m:mods/m:titleInfo', 'm' => ns).size).to eq 2
  end

  it 'writes attribute predicates as attributes' do
    condition = xml.at_xpath('/m:mods/m:accessCondition', 'm' => ns)
    expect(condition['type']).to eq 'use and reproduction'
  end

  it 'writes the label of a controlled value and keeps its URI' do
    condition = xml.at_xpath('/m:mods/m:accessCondition', 'm' => ns)
    expect(condition.text).to eq 'Attribution 3.0 United States'
    expect(condition['xlink:href']).to eq 'http://creativecommons.org/licenses/by/3.0/us/'

    geographic = xml.at_xpath('/m:mods/m:subject/m:geographic', 'm' => ns)
    expect(geographic.text).to eq 'Birmingham, Alabama, United States'
    expect(geographic['valueURI']).to eq 'http://sws.geonames.org/4049979/'

    language = xml.at_xpath('/m:mods/m:language/m:languageTerm', 'm' => ns)
    expect(language['valueURI']).to eq 'http://id.loc.gov/vocabulary/iso639-2/eng'
  end

  context 'with a controlled value read from a field other than _tesim' do
    let(:document) { SolrDocument.new('id' => 'abc123', 'license_ssim' => ['http://creativecommons.org/licenses/by/3.0/us/']) }
    let(:mappings) do
      [{ property: 'license', mapping: 'mods:accessCondition', index_keys: ['license_ssim'] }]
    end

    it 'writes the value itself, not the value posing as its own label' do
      condition = xml.at_xpath('/m:mods/m:accessCondition', 'm' => ns)
      expect(condition.text).to eq 'http://creativecommons.org/licenses/by/3.0/us/'
      expect(condition['xlink:href']).to be_nil
    end
  end

  it 'orders location children as the schema requires, whatever the mapping order' do
    expect(xml.xpath('/m:mods/m:location/*', 'm' => ns).map(&:name))
      .to eq %w[physicalLocation url url]
    expect(values_at('/m:mods/m:location/m:url[@usage="primary"]')).to eq [item_url]
  end

  context 'with mappings in an unconventional order' do
    let(:mappings) { super().reverse }

    it 'orders top-level elements as MODS conventionally does' do
      expect(xml.root.element_children.map(&:name)).to eq %w[
        titleInfo titleInfo name name originInfo language language subject subject subject location
        accessCondition recordInfo
      ]
    end
  end

  it 'identifies the record' do
    expect(values_at('/m:mods/m:recordInfo/m:recordIdentifier')).to eq ['abc123']
    expect(values_at('/m:mods/m:recordInfo/m:recordCreationDate')).to eq ['2020-01-01T00:00:00Z']
  end

  context 'with two properties indexed to the same field and mapped to the same element' do
    let(:mappings) do
      %w[creator creator_hidden].map do |property|
        { property:, mapping: %(mods:name[mods:role/mods:roleTerm="creator"]/mods:namePart),
          index_keys: %w[creator_sim creator_tesim] }
      end
    end

    it 'writes each value once' do
      expect(values_at('/m:mods/m:name/m:namePart')).to eq ['Smith, Jo', 'Doe, Al']
    end
  end

  context 'with a mapping it cannot parse' do
    let(:mappings) do
      [{ property: 'creator', mapping: %(mods:name[mods:role/mods:roleTerm[contains(.,'Creator')]]/mods:namePart),
         index_keys: ['creator_tesim'] }]
    end

    before { Hyku::Mods::MappingPath.cache.clear }

    it 'leaves the property out and warns once' do
      allow(Rails.logger).to receive(:warn)

      2.times { described_class.new(document, mappings:).to_xml }

      expect(values_at('/m:mods/m:name')).to be_empty
      expect(Rails.logger).to have_received(:warn).with(/Unsupported MODS mapping/).once
    end
  end
end
