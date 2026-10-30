# frozen_string_literal: true

# TEMPORARY: re-evaluate and remove when samvera/hyrax#7732 is in the bundled Hyrax, with the overrides these examples cover
RSpec.describe Hyrax::CollectionsHelper, type: :helper do
  let(:document) do
    SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['CollectionResource'], 'schema_version_ssi' => '1',
                     'title_tesim' => ['Harbor Records'], 'abstract_tesim' => ['Maps of the harbor.'],
                     'call_number_tesim' => ['MS.0951'], 'resource_link_tesim' => ['https://example.com/harbor'])
  end
  let(:presenter) { Hyrax::CollectionPresenter.new(document, Ability.new(nil)) }
  let(:on_collections) { { 'class' => ['CollectionResource'] } }
  let(:properties) do
    { 'abstract' => { 'available_on' => on_collections, 'indexing' => ['abstract_tesim'], 'data_type' => 'array',
                      'display_label' => { 'default' => 'Summary' }, 'view' => { 'html_dl' => true } },
      'call_number' => { 'available_on' => on_collections, 'indexing' => ['call_number_tesim'], 'data_type' => 'array', 'view' => { 'html_dl' => true } },
      'resource_link' => { 'available_on' => on_collections, 'indexing' => ['resource_link_tesim'], 'data_type' => 'array',
                           'view' => { 'html_dl' => true, 'collection_page' => false } },
      'admin_note' => { 'available_on' => on_collections, 'indexing' => ['admin_note_tesim', 'admin_only'], 'data_type' => 'array',
                        'view' => { 'html_dl' => true } },
      'donors' => { 'available_on' => on_collections, 'type' => 'hash', 'view' => { 'html_dl' => true, 'collection_page' => false } },
      'relationships' => { 'available_on' => on_collections, 'type' => 'hash', 'view' => { 'html_dl' => true, 'display' => 'card' } } }
  end

  before do
    allow(Hyrax::FlexibleSchema).to receive_messages(current_version: { 'properties' => properties }, current_schema_id: 1)
    allow(presenter).to receive(:editor?).and_return(false)
    allow(helper).to receive(:compound_card_field?) { |_presenter, field| field.to_sym == :relationships }
    without_partial_double_verification { allow(helper).to receive(:current_user).and_return(nil) }
  end

  after do
    Hyku::CollectionProfileReaders.readers.each do |reader|
      [Hyrax::CollectionPresenter, Hyrax::AdminSetPresenter].each { |klass| klass.send(:remove_method, reader) if klass.method_defined?(reader, false) }
    end
    Hyku::CollectionProfileReaders.readers.clear
  end

  describe '#collection_terms_for' do
    it "lists the presenter's own terms with values, as an app may define them, when no list is set" do
      allow(presenter).to receive(:terms_with_values).and_return(%i[total_items abstract])

      expect(helper.collection_terms_with_values(presenter)).to eq %i[total_items abstract]
    end

    it "keeps the presenter's terms when the app sets no list and the page does not ask for the profile's" do
      expect(helper.collection_terms_for(presenter)).to eq presenter.terms
    end

    it "leaves out of the presenter's terms a field the profile limits to admins or editors" do
      properties['abstract']['indexing'] << 'editor_only'
      allow(presenter).to receive_messages(terms: %i[total_items abstract admin_note call_number], editor?: false)

      expect(helper.collection_terms_for(presenter)).to eq %i[total_items call_number]
    end

    it "leaves out of the presenter's terms a field, compound or not, the profile keeps off collection pages" do
      properties['call_number']['view']['collection_page'] = false
      allow(presenter).to receive(:terms).and_return(%i[total_items abstract call_number donors])

      expect(helper.collection_terms_for(presenter)).to eq %i[total_items abstract]
    end

    it "keeps a field limited to admins or editors for a viewer who is one" do
      properties['abstract']['indexing'] << 'editor_only'
      admin = instance_double(::User, admin?: true)
      without_partial_double_verification { allow(helper).to receive(:current_user).and_return(admin) }
      allow(presenter).to receive_messages(terms: %i[abstract admin_note], editor?: true)

      expect(helper.collection_terms_for(presenter)).to eq %i[abstract admin_note]
    end

    it "leaves out a field whose profile entry is marked admin-only" do
      properties['call_number']['admin_only'] = true

      expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[abstract]
    end

    it "shows an admin who does not edit the collection its admin-only fields, not its editor-only ones" do
      properties['abstract']['indexing'] << 'editor_only'
      without_partial_double_verification { allow(helper).to receive(:current_user).and_return(instance_double(::User, admin?: true)) }

      expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[call_number admin_note]
    end

    it "shows an editor who is not an admin its editor-only fields, not its admin-only ones" do
      properties['abstract']['indexing'] << 'editor_only'
      without_partial_double_verification { allow(helper).to receive(:current_user).and_return(instance_double(::User, admin?: false)) }
      allow(presenter).to receive(:editor?).and_return(true)

      expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[abstract call_number]
    end

    it "lists the profile's properties a collection page may show, in profile order, when the page asks for them" do
      expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[abstract call_number]
    end

    it 'keeps a featured property on the collection page' do
      properties['call_number']['view']['position'] = 'featured'

      expect(helper.collection_terms_for(presenter, dynamic: true)).to include(:call_number)
    end

    context "with the app's own list" do
      before { allow(Hyrax.config).to receive(:collection_terms).and_return(%i[call_number title abstract resource_link admin_note relationships]) }

      it 'shows the listed properties in its order, leaving out those the profile lacks, keeps off collection pages, cards or hides' do
        expect(helper.collection_terms_for(presenter)).to eq %i[call_number abstract]
      end

      it "uses the app's list even where the page asks for the profile's" do
        expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[call_number abstract]
      end

      it "labels a listed property with the profile's label" do
        expect(helper.collection_metadata_label(presenter, :abstract)).to eq 'Summary'
      end

      context 'with a controlled property' do
        let(:catalog_config) { Blacklight::Configuration.new }

        before do
          properties['subject'] = { 'available_on' => on_collections, 'indexing' => %w[subject_tesim subject_sim], 'data_type' => 'array',
                                    'view' => { 'html_dl' => true, 'render_as' => 'faceted' } }
          allow(Hyrax.config).to receive(:collection_terms).and_return(%i[subject])
          config = catalog_config
          helper.define_singleton_method(:blacklight_config) { config }
        end

        def subject_link(document)
          collection = Hyrax::CollectionPresenter.new(document, Ability.new(nil))
          link = Capybara.string(helper.collection_metadata_value(collection, :subject).to_s).find('a')
          [link.text, CGI.unescape(link['href'])]
        end

        it 'shows its indexed label and links through the label facet the catalog registers' do
          catalog_config.add_facet_field 'subject_label_sim'
          labeled = SolrDocument.new(document.to_h.merge('subject_tesim' => ['http://id.loc.gov/subjects/sh1'], 'subject_label_tesim' => ['Harbors']))

          text, href = subject_link(labeled)
          expect(text).to eq 'Harbors'
          expect(href).to include('f[subject_label_sim][]=Harbors')
        end

        it 'shows the stored value and links through its own facet when no label is indexed' do
          unlabeled = SolrDocument.new(document.to_h.merge('subject_tesim' => ['http://id.loc.gov/subjects/sh1']))

          text, href = subject_link(unlabeled)
          expect(text).to eq 'http://id.loc.gov/subjects/sh1'
          expect(href).to include('f[subject_sim][]=http://id.loc.gov/subjects/sh1')
        end
      end

      it "renders a listed property's value with the profile's view settings" do
        expect(helper.collection_metadata_value(presenter, :call_number)).to include('MS.0951')
      end

      context 'with a profile render term the presenter cannot read' do
        let(:located) { Hyrax::CollectionPresenter.new(document, Ability.new(nil)) }

        before do
          properties['based_near'] = { 'available_on' => on_collections, 'indexing' => ['based_near_tesim'],
                                       'display_label' => { 'default' => 'Place of creation' },
                                       'view' => { 'html_dl' => true, 'render_term' => 'based_near_label' } }
        end

        it 'renders the value as Hyrax does' do
          allow(located).to receive(:based_near).and_return(['Knoxville'])
          allow(Hyrax::PresenterRenderer).to receive(:new).and_return(instance_double(Hyrax::PresenterRenderer, value: 'Knoxville'))

          expect(helper.collection_metadata_value(located, :based_near)).to eq 'Knoxville'
        end

        it "labels it with the profile's label" do
          expect(helper.collection_metadata_label(located, :based_near)).to eq 'Place of creation'
        end
      end

      it "ignores another collection's profile readers on a collection saved without the profile" do
        presenter.abstract
        plain = Hyrax::CollectionPresenter.new(SolrDocument.new('id' => 'c3', 'has_model_ssim' => ['CollectionResource'],
                                                                'title_tesim' => ['Harbor Records'], 'call_number_tesim' => ['MS.0951']),
                                               Ability.new(nil))

        expect(helper.collection_terms_with_values(plain)).to eq %i[title]
      end

      it 'skips a listed term only the presenter defines, which the page cannot look up' do
        allow(Hyrax.config).to receive(:collection_terms).and_return(%i[title total_viewable_items])
        plain = Hyrax::CollectionPresenter.new(SolrDocument.new('id' => 'c4', 'has_model_ssim' => ['CollectionResource'],
                                                                'title_tesim' => ['Harbor Records']), Ability.new(nil))

        expect(helper.collection_terms_with_values(plain)).to eq %i[title]
      end

      it 'skips a listed property a collection saved without the profile cannot read' do
        plain = Hyrax::CollectionPresenter.new(SolrDocument.new('id' => 'c2', 'has_model_ssim' => ['CollectionResource'],
                                                                'title_tesim' => ['Harbor Records']), Ability.new(nil))

        expect(helper.collection_terms_with_values(plain)).to eq %i[title]
      end
    end
  end

  describe '#collection_terms_for on an admin set that defines a context' do
    let(:profile) do
      { 'classes' => { 'AdminSetResource' => {} },
        'properties' => {
          'keyword' => { 'available_on' => { 'class' => ['AdminSetResource'] }, 'indexing' => ['keyword_tesim'], 'view' => { 'html_dl' => true } },
          'keyword_closed' => { 'name' => 'keyword', 'available_on' => { 'class' => ['AdminSetResource'], 'context' => ['closed_context'] },
                                'indexing' => ['keyword_tesim'], 'view' => { 'html_dl' => true, 'collection_page' => false } }
        } }
    end
    let(:schema) { Hyrax::FlexibleSchema.new(profile:).tap { |record| record.save(validate: false) } }
    let(:admin_set) do
      Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a1', 'has_model_ssim' => ['AdminSetResource'], 'schema_version_ssi' => schema.id.to_s,
                                                    'contexts_ssim' => ['closed_context'], 'keyword_tesim' => ['harbors']), Ability.new(nil))
    end

    before { allow(Hyrax::FlexibleSchema).to receive_messages(current_version: profile, current_schema_id: schema.id) }

    it "takes the property's view settings from its entry with no context" do
      expect(helper.collection_terms_for(admin_set, dynamic: true)).to include(:keyword)
    end
  end
end
