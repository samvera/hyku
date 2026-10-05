# frozen_string_literal: true

RSpec.describe 'IIIF manifest metadata under a flexible profile' do
  subject(:presenter) do
    Hyrax::IiifManifestPresenter.new(document).tap { |p| p.base_url = 'http://test.host' }
  end

  let(:profile) { YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml')) }
  let(:schema) { Hyrax::FlexibleSchema.create(profile:) }
  let(:fields) { {} }
  let(:document) do
    SolrDocument.new({ 'id' => 'work-1',
                       'has_model_ssim' => ['GenericWorkResource'],
                       'schema_version_ssi' => schema.version.to_s,
                       'title_tesim' => ['A Title'],
                       'description_tesim' => ['A description'] }.merge(fields))
  end

  before { allow(Hyrax.config).to receive(:flexible?).and_return(true) }

  after { schema.destroy }

  def entry(label)
    presenter.manifest_metadata.find { |e| e['label'].values.flatten.include?(label) }
  end

  def links(label)
    Nokogiri::HTML.fragment(entry(label)['value']['none'].join).css('a').map { |a| [a.text, a['href']] }
  end

  describe '#manifest_metadata' do
    context 'with a controlled vocabulary value' do
      let(:fields) { { 'resource_type_tesim' => ['id_1'], 'resource_type_label_tesim' => ['Readable Term'] } }

      it 'shows the term label linked to its facet, as the show page does' do
        expect(links('Resource Type'))
          .to eq [['Readable Term', 'http://test.host/catalog?f%5Bresource_type_sim%5D%5B%5D=id_1&locale=en']]
      end
    end

    context 'with properties the profile orders' do
      let(:fields) { { 'subject_tesim' => ['Cats'], 'creator_tesim' => ['Ada'], 'keyword_tesim' => ['felines'] } }

      it 'leads with title and description, then follows the profile order' do
        expect(presenter.manifest_metadata.map { |e| e['label']['en'].first })
          .to eq ['Title', 'Description', 'Creator', 'Keyword', 'Subject']
      end
    end

    context "when the work's schema version no longer exists" do
      let(:document) do
        SolrDocument.new('id' => 'work-1', 'has_model_ssim' => ['GenericWorkResource'],
                         'schema_version_ssi' => (schema.version + 1000).to_s,
                         'title_tesim' => ['A Title'], 'description_tesim' => ['A description'], 'creator_tesim' => ['Ada'])
      end

      it 'falls back to the latest profile, as the schema loader does' do
        expect(presenter.manifest_metadata.map { |e| e['label']['en'].first }).to eq ['Title', 'Description', 'Creator']
      end
    end

    # Production eager-loads sparql, whose Hash#deep_dup returns a plain Hash with
    # string keys, which Hyrax's attribute helpers cannot read.
    context 'once the sparql gem is loaded, as it is in production' do
      before do
        require 'sparql/algebra'
        profile['properties']['subject']['admin_only'] = true
      end

      let(:fields) { { 'subject_tesim' => ['Cats'] } }

      it 'still hides admin-only properties and uses profile labels' do
        I18n.with_locale(:es) do
          expect(presenter.manifest_metadata.to_s).not_to include 'Cats'
          expect(presenter.manifest_metadata.first['label']).to eq('es' => ['Título'])
        end
      end
    end

    context 'in another locale' do
      it "uses the profile's label for that locale" do
        I18n.with_locale(:es) do
          expect(presenter.manifest_metadata.first['label']).to eq('es' => ['Título'])
        end
      end
    end

    context 'when the profile has no description' do
      before { profile['properties'].delete('description') }

      let(:fields) { { 'abstract_tesim' => ['An abstract'], 'creator_tesim' => ['Ada'] } }

      it 'leads with the abstract in its place' do
        expect(presenter.manifest_metadata.map { |e| e['label']['en'].first }).to eq ['Title', 'Abstract', 'Creator']
      end
    end

    context 'when the work belongs to a collection' do
      let(:fields) { { 'member_of_collection_ids_ssim' => ['col-1'], 'creator_tesim' => ['Ada'] } }

      before do
        allow(Hyrax::CollectionMemberService).to receive(:run)
          .and_return([SolrDocument.new('id' => 'col-1', 'title_tesim' => ['Cat Photos'])])
      end

      it 'links the collection after the title and description' do
        expect(presenter.manifest_metadata.map { |e| e['label']['en'].first })
          .to eq ['Title', 'Description', 'Collection', 'Creator']
        expect(links('Collection')).to eq [['Cat Photos', 'http://test.host/collections/col-1']]
      end

      it 'lists only the collections an anonymous visitor can see' do
        presenter.manifest_metadata

        expect(Hyrax::CollectionMemberService)
          .to have_received(:run).with(document, satisfy { |ability| ability.current_user.new_record? })
      end
    end

    context 'with a property the show page hides from visitors' do
      let(:document) do
        SolrDocument.new('id' => 'oer-1', 'has_model_ssim' => ['OerResource'],
                         'schema_version_ssi' => schema.version.to_s,
                         'title_tesim' => ['A Title'], 'admin_note_tesim' => ['Internal only'])
      end

      it 'leaves it out, since the manifest is cached for everyone' do
        expect(presenter.manifest_metadata.to_s).not_to include 'Internal only'
      end
    end

    context 'with a property the profile limits to admins' do
      before { profile['properties']['subject']['admin_only'] = true }

      let(:fields) { { 'subject_tesim' => ['Cats'] } }

      it 'leaves it out' do
        expect(presenter.manifest_metadata.to_s).not_to include 'Cats'
      end
    end

    context 'with a property the show page features above its other rows' do
      before { profile['properties']['subject']['view']['position'] = 'featured' }

      let(:fields) { { 'subject_tesim' => ['Cats'] } }

      it 'includes it, since every visitor sees it' do
        expect(entry('Subject')['value']['none'].join).to include 'Cats'
      end
    end

    context 'with a compound property' do
      let(:fields) do
        { 'participants_json_ss' => [{ name: 'Ada', role: 'Author' }, { name: 'Grace', role: 'Editor' }].to_json }
      end

      it 'keeps each entry, and each sub-property, apart' do
        html = Nokogiri::HTML.fragment(entry('Participants')['value']['none'].join)

        expect(html.css('p').map { |p| p.inner_html.split('<br>').map { |part| Nokogiri::HTML.fragment(part).text.squish } })
          .to eq [['Name: Ada', 'Role: Author'], ['Name: Grace', 'Role: Editor']]
      end
    end

    context 'with a compound the show page renders as a card' do
      before { profile['properties']['participants']['view']['display'] = 'card' }

      let(:fields) { { 'participants_json_ss' => [{ name: 'Ada', role: 'Author' }].to_json } }

      it 'includes it, since every visitor sees the card' do
        expect(entry('Participants')['value']['none'].join).to include 'Ada'
      end
    end

    context 'with a property the profile keeps off the show page' do
      before { profile['properties']['subject']['view']['show_page'] = false }

      let(:fields) { { 'subject_tesim' => ['Cats'] } }

      it 'leaves it out' do
        expect(presenter.manifest_metadata.to_s).not_to include 'Cats'
      end
    end

    context 'when the tenant renders user input as markdown' do
      before { allow(Flipflop).to receive(:treat_some_user_inputs_as_markdown?).and_return(true) }

      let(:fields) { { 'description_tesim' => ["- **one**\n- two"] } }

      it 'keeps a list in a value as one value' do
        expect(entry('Description')['value']['none'].size).to eq 1
      end

      it 'drops tags outside the IIIF HTML subset' do
        expect(entry('Description')['value']['none'].join).not_to include '<strong>'
      end
    end

    context 'with markup in a value' do
      let(:fields) { { 'subject_tesim' => ['<script>alert(1)</script>Cats'] } }

      it 'never emits it as a tag' do
        expect(presenter.manifest_metadata.to_s).not_to include '<script'
      end
    end
  end
end
