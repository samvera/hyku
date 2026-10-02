# frozen_string_literal: true

RSpec.describe 'IiifPrint.manifest_metadata_from' do
  subject(:metadata) { IiifPrint.manifest_metadata_from(work: document, presenter:) }

  let(:presenter) { Struct.new(:base_url, :ability).new('http://test.host', nil) }
  let(:schema) { Hyrax::FlexibleSchema.create(profile: YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml'))) }

  after { schema.destroy }

  def labels
    metadata.map { |entry| entry['label'].values.flatten.first }
  end

  context 'for a work indexed under a flexible schema' do
    before { allow(Hyrax.config).to receive(:flexible?).and_return(true) }

    let(:document) do
      SolrDocument.new('id' => 'work-1', 'has_model_ssim' => ['GenericWorkResource'], 'schema_version_ssi' => schema.version.to_s,
                       'title_tesim' => ['A Title'], 'resource_type_tesim' => ['id_1'], 'resource_type_label_tesim' => ['Readable Term'])
    end

    it 'builds the metadata from the profile' do
      expect(labels).to eq ['Title', 'Resource Type']
      expect(metadata.last['value']['none'].join).to include('Readable Term')
    end
  end

  context 'for a work indexed under a flexible schema while flexible metadata is turned off' do
    before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

    let(:document) do
      SolrDocument.new('id' => 'work-1', 'has_model_ssim' => ['GenericWorkResource'], 'schema_version_ssi' => schema.version.to_s,
                       'title_tesim' => ['A Title'], 'creator_tesim' => ['Ada'])
    end

    it "keeps IiifPrint's metadata" do
      expect(metadata).to eq IiifPrint.manifest_metadata_for(work: document, current_ability: nil, base_url: 'http://test.host')
    end
  end

  context 'for a work indexed without a flexible schema' do
    let(:document) { SolrDocument.new('id' => 'work-1', 'has_model_ssim' => ['GenericWork'], 'title_tesim' => ['A Title'], 'creator_tesim' => ['Ada']) }

    it "keeps IiifPrint's metadata" do
      expect(metadata).to eq IiifPrint.manifest_metadata_for(work: document, current_ability: nil, base_url: 'http://test.host')
    end
  end
end
