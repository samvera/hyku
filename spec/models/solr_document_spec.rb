# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument, type: :model do
  let(:solr_document) { described_class.new }
  let(:query_result) do
    { 'response' => { 'docs' => [
      { 'id' => '123', 'title_tesim' => ['Title 1'] },
      { 'id' => '456', 'title_tesim' => ['Title 2'] }
    ] } }
  end

  before do
    allow(Hyrax::SolrService).to receive(:post).and_return(query_result)
  end

  describe '#load_parent_docs' do
    it 'loads parent documents from Solr' do
      parent_docs = solr_document.load_parent_docs
      expect(parent_docs.first).to be_a SolrDocument
      expect(parent_docs.size).to eq 2
      expect(parent_docs.first.id).to eq '123'
    end
  end

  describe '#query' do
    it 'queries Solr with provided parameters' do
      result = solr_document.query("some_query", rows: 2)
      expect(result).to be_an Array
      expect(result.size).to eq 2
      expect(result.map { |r| r['id'] }).to eq ["123", "456"]
    end

    context 'when Solr response does not contain docs' do
      let(:query_result) { { 'response' => {} } }

      it 'returns an empty array' do
        result = solr_document.query("some_query", rows: 2)
        expect(result).to eq([])
      end
    end
  end

  describe '#to_semantic_values' do
    subject { solr_document.to_semantic_values }
    let(:solr_document) { SolrDocument.new(attributes) }
    let(:attributes) do
      { id: '123',
        has_model_ssim: ['GenericWork'],
        account_cname_tesim: ['test.hyku'],
        thumbnail_path_ss: '/thumbnail.png',
        title_tesim: ['A Title'],
        description_tesim: ['A description'],
        abstract_tesim: ['An abstract'] }
    end

    it 'includes show page and thumbnail urls in identifier' do
      expect(subject[:identifier]).to include('https://test.hyku/concern/generic_works/123')
      expect(subject[:identifier]).to include('https://test.hyku/thumbnail.png')
    end

    shared_examples_for 'maps properties to dc terms' do
      it "uses the works' schema match properties to dc terms" do
        klass_name = GenericWorkResource
        expect(solr_document.hydra_model).to eq klass_name

        schema_key = klass_name.schema.keys.find { |k| k.name == :abstract }
        expect(schema_key.meta.dig('mappings', 'simple_dc_pmh')).to eq 'dc:description'

        schema_key = klass_name.schema.keys.find { |k| k.name == :description }
        expect(schema_key.meta.dig('mappings', 'simple_dc_pmh')).to eq 'dc:description'

        expect(subject[:description]).to include('A description')
        expect(subject[:description]).to include('An abstract')
      end
    end

    shared_examples_for 'keeps controlled vocabulary labels out of dc terms' do
      let(:attributes) do
        { id: '123',
          has_model_ssim: ['GenericWork'],
          title_tesim: ['A Title'],
          title_label_tesim: ['A Label Nobody Should Harvest'],
          license_tesim: ['http://creativecommons.org/licenses/by/3.0/us/'],
          license_label_tesim: ['Attribution 3.0 United States'],
          rights_statement_tesim: ['local_auth_123'],
          rights_statement_label_tesim: ['Opaque Term'] }
      end

      it 'harvests no label field under any dc term' do
        labels = ['A Label Nobody Should Harvest', 'Attribution 3.0 United States', 'Opaque Term']

        expect(subject.values.flatten).not_to include(*labels)
      end

      it 'still harvests the stored value' do
        expect(subject.values.flatten).to include('A Title')
      end
    end

    context 'when not using flexible metadata' do
      it_behaves_like 'maps properties to dc terms'
      it_behaves_like 'keeps controlled vocabulary labels out of dc terms'
    end

    context 'when using flexible metadata' do
      let(:profile_file_path) { Rails.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml') }
      let(:profile_data) { YAML.load_file(profile_file_path) }
      around do |example|
        original_value = Hyrax.config.flexible
        Hyrax.config.flexible = true
        # current_schema_id is the newest row, so this fixture schema (which omits
        # some properties, e.g. redirects) shadows the default for the rest of the
        # process; delete it after the example so later specs see the real schema.
        schema = Hyrax::FlexibleSchema.create(profile: profile_data)
        example.run
        schema.destroy
        Hyrax.config.flexible = original_value
      end

      it_behaves_like 'maps properties to dc terms'
      it_behaves_like 'keeps controlled vocabulary labels out of dc terms'
    end
  end

  describe 'Dublin Core values' do
    subject(:values) { SolrDocument.new(attributes).to_semantic_values }
    let(:attributes) do
      { id: '123', has_model_ssim: ['GenericWork'], title_tesim: ['A Title'], subject_tesim: ['Cats'],
        creator_tesim: ['Smith, Jo'], language_tesim: ['English'], publisher_sim: ['Facet Only Press'] }
    end

    shared_examples_for 'Dublin Core values' do
      it 'lists the mapped elements in Dublin Core order' do
        expect(values.keys - [:identifier]).to eq %i[creator language subject title]
      end

      it "reads only each property's text field, leaving out a value indexed only for facets" do
        expect(values).not_to have_key(:publisher)
      end

      context 'with a compound' do
        let(:attributes) do
          super().merge(participants_json_ss: [{ name: 'Doe, Al', role: 'Editor' }].to_json,
                        identifiers_json_ss: [{ value: '10.1234/abc', type: 'DOI' }].to_json)
        end

        it 'writes each sub-property value under its element' do
          expect(values[:contributor]).to eq ['Doe, Al']
          expect(values[:identifier]).to include('10.1234/abc')
        end
      end
    end

    context 'when not using flexible metadata' do
      it_behaves_like 'Dublin Core values'
    end

    context 'when using flexible metadata' do
      around do |example|
        schema = Hyrax::FlexibleSchema.new(profile: YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml')))
        schema.save(validate: false)
        example.run
        schema.destroy
      end

      before { allow(Hyrax.config).to receive(:flexible_classes).and_return(['GenericWorkResource']) }

      it_behaves_like 'Dublin Core values'
    end
  end

  describe '#to_mods' do
    subject(:mods) { Nokogiri::XML(solr_document.to_mods) }
    let(:solr_document) { SolrDocument.new(attributes) }
    let(:attributes) do
      { id: '123',
        has_model_ssim: ['GenericWork'],
        account_cname_tesim: ['test.hyku'],
        title_tesim: ['A Title'],
        creator_tesim: ['Smith, Jo'] }
    end
    let(:creator_mapping) { %(mods:name[mods:role/mods:roleTerm="creator"]/mods:namePart) }

    def mods_values(path)
      mods.xpath(path, 'm' => Hyku::Mods::ElementTree::NAMESPACE).map(&:text)
    end

    it 'links to the show page' do
      expect(mods_values('//m:location/m:url[@usage="primary"]'))
        .to eq ['https://test.hyku/concern/generic_works/123']
    end

    context 'with a thumbnail' do
      let(:attributes) { super().merge(thumbnail_path_ss: '/downloads/456?file=thumbnail') }

      it 'links to it as a preview' do
        expect(mods_values('//m:location/m:url[@access="preview"]'))
          .to eq ['https://test.hyku/downloads/456?file=thumbnail']
      end
    end

    context 'with only the placeholder thumbnail of a work without files' do
      let(:attributes) { super().merge(thumbnail_path_ss: '/assets/default-f936e9c3.png') }

      it 'offers no preview' do
        expect(mods_values('//m:location/m:url[@access="preview"]')).to be_empty
      end
    end

    context "with only the tenant's default work image" do
      let(:attributes) { super().merge(thumbnail_path_ss: '/uploads/site/default_work_image/1/default.png') }

      before do
        allow(Site.instance).to receive(:default_work_image)
          .and_return(instance_double(Hyku::AvatarUploader, url: '/uploads/site/default_work_image/1/default.png'))
      end

      it 'offers no preview' do
        expect(mods_values('//m:location/m:url[@access="preview"]')).to be_empty
      end
    end

    context 'when not using flexible metadata' do
      let(:model) do
        mapping = creator_mapping
        Class.new(Hyrax::Work) do
          attribute :creator, Valkyrie::Types::Array.of(Valkyrie::Types::String)
                                                    .meta('mappings' => { 'mods_oai_pmh' => mapping },
                                                          'index_keys' => ['creator_sim', 'creator_tesim'])
        end
      end

      before { allow(solr_document).to receive(:hydra_model).and_return(model) }

      it 'maps properties from the metadata YAML' do
        expect(mods_values('//m:name/m:namePart')).to eq ['Smith, Jo']
        expect(mods_values('//m:titleInfo/m:title')).to eq ['A Title']
      end
    end

    context 'when using flexible metadata' do
      let(:profile_data) do
        YAML.load_file(Rails.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')).tap do |profile|
          profile['properties']['creator']['mappings'] = { 'mods_oai_pmh' => creator_mapping }
        end
      end

      around do |example|
        schema = Hyrax::FlexibleSchema.create(profile: profile_data)
        example.run
        schema.destroy
      end

      before { allow(Hyrax.config).to receive(:flexible_classes).and_return(['GenericWorkResource']) }

      it 'maps properties from the metadata profile' do
        expect(mods_values('//m:name/m:namePart')).to eq ['Smith, Jo']
        expect(mods_values('//m:titleInfo/m:title')).to eq ['A Title']
      end
    end

    shared_examples_for 'writes each participant with their role' do
      let(:attributes) do
        { id: '123', has_model_ssim: ['GenericWork'], title_tesim: ['A Title'],
          participants_json_ss: [{ name: 'Smith, Jo', role: 'Author' }, { name: 'Doe, Al', role: 'Editor' }].to_json }
      end

      it 'writes one name per entry, holding its role' do
        names = mods.xpath('//m:name', 'm' => Hyku::Mods::ElementTree::NAMESPACE).map do |name|
          [name.at_xpath('m:namePart', 'm' => Hyku::Mods::ElementTree::NAMESPACE)&.text,
           name.at_xpath('m:role/m:roleTerm', 'm' => Hyku::Mods::ElementTree::NAMESPACE)&.text]
        end

        expect(names).to eq [['Smith, Jo', 'Author'], ['Doe, Al', 'Editor']]
      end
    end

    context 'with a compound when not using flexible metadata' do
      it_behaves_like 'writes each participant with their role'
    end

    context 'with a compound when using flexible metadata' do
      let(:profile_data) do
        defaults = YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml'))['properties']
        YAML.load_file(Rails.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')).tap do |profile|
          profile['properties'].merge!(defaults.slice('participants', 'participant_name', 'participant_role'))
        end
      end

      around do |example|
        schema = Hyrax::FlexibleSchema.new(profile: profile_data)
        schema.save(validate: false)
        example.run
        schema.destroy
      end

      before { allow(Hyrax.config).to receive(:flexible_classes).and_return(['GenericWorkResource']) }

      it_behaves_like 'writes each participant with their role'
    end
  end
end
