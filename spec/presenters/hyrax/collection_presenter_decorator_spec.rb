# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::CollectionPresenter, type: :decorator do
  describe '.terms' do
    it 'does not include size' do
      expect(described_class.terms.size).to be_positive
      expect(described_class.terms).not_to include(:size)
    end
  end

  describe '#collection_type_badge' do
    subject { presenter.collection_type_badge }

    # We're decorating an alternate base class so that we don't need the full pre-amble for testing
    # our decoration.  In other words, let's trust Hyrax::CollectionPresenter's specs for the
    # "super" method call.
    let(:base_class) do
      Class.new do
        def collection_type_badge
          "<span>"
        end
        prepend Hyrax::CollectionPresenterDecorator
      end
    end
    let(:presenter) { base_class.new }

    before { allow(Site).to receive(:account).and_return(account) }

    context 'when the Site.account is nil' do
      let(:account) { nil }

      it { is_expected.to eq("") }
    end

    context 'when the Site.account is search_only' do
      let(:account) { FactoryBot.build(:account, search_only: true) }

      it { is_expected.to eq("") }
    end

    context 'when the Site.account is NOT search_only' do
      let(:account) { FactoryBot.build(:account, search_only: false) }

      it { is_expected.to start_with("<span") }
    end

    context 'super_method' do
      subject { Hyrax::CollectionPresenter.instance_method(:collection_type_badge).super_method }

      let(:account) { nil }

      it 'is Hyrax::CollectionPresenter#collection_type_badge' do
        expect(subject.source_location.first).to end_with("app/presenters/hyrax/collection_presenter.rb")
      end
    end
  end

  # TEMPORARY: re-evaluate and remove when samvera/hyrax#7732 is in the bundled Hyrax
  context 'with a flexible metadata profile' do
    let(:document) do
      SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['CollectionResource'], 'schema_version_ssi' => '1',
                       'call_number_tesim' => ['MS.0951'], 'rights_statement_tesim' => ['http://rightsstatements.org/vocab/InC/1.0/'])
    end
    let(:presenter) { described_class.new(document, Ability.new(nil)) }
    let(:on_collections) { { 'class' => %w[CollectionResource AdminSetResource] } }
    let(:properties) do
      { 'call_number' => { 'available_on' => on_collections, 'indexing' => ['call_number_tesim'], 'data_type' => 'array' },
        'rights_statement_optional' => { 'name' => 'rights_statement', 'available_on' => on_collections, 'indexing' => ['rights_statement_tesim'],
                                         'data_type' => 'array' } }
    end

    before do
      Hyrax::Current.flexible_schema_profiles = nil
      allow(Hyrax::FlexibleSchema).to receive_messages(current_version: { 'properties' => properties }, current_schema_id: 1)
    end

    after do
      Hyku::CollectionProfileReaders.readers.each do |reader|
        [Hyrax::CollectionPresenter, Hyrax::AdminSetPresenter].each { |klass| klass.send(:remove_method, reader) if klass.method_defined?(reader, false) }
      end
      Hyku::CollectionProfileReaders.readers.clear
    end

    it "reads a property's indexed values from the profile it is given, not the one that defined its reader" do
      presenter.call_number
      properties['call_number']['indexing'] = ['call_number_ssim']
      later = SolrDocument.new(document.to_h.merge('call_number_ssim' => ['MS.0952']))

      expect(described_class.new(later, Ability.new(nil)).call_number).to eq ['MS.0952']
    end

    it 'reads a profile property Hyrax gives collections no reader for' do
      expect(presenter.call_number).to eq ['MS.0951']
    end

    it "names a profile property's reader after its name, not its profile key" do
      expect(presenter.rights_statement).to eq ['http://rightsstatements.org/vocab/InC/1.0/']
    end

    it "reads a property through the document's own reader when the document has one, as the page's value check does" do
      properties['date_modified'] = { 'available_on' => on_collections, 'data_type' => 'string' }

      expect(presenter.date_modified).to eq presenter[:date_modified]
    end

    it 'builds no compound schema while defining readers' do
      allow(Hyrax::CompoundSchema).to receive(:for_solr_document).and_call_original
      presenter

      expect(Hyrax::CompoundSchema).not_to have_received(:for_solr_document)
    end

    it 'reads a single-valued property as its value' do
      properties['shelf'] = { 'available_on' => on_collections, 'indexing' => ['shelf_ssi'], 'data_type' => 'string', 'multiple' => false }
      shelved = described_class.new(SolrDocument.new(document.to_h.merge('shelf_ssi' => 'Vault 2')), Ability.new(nil))

      expect(shelved.shelf).to eq 'Vault 2'
    end

    it 'reads a property whose cardinality allows many values as a list' do
      properties['shelf'] = { 'available_on' => on_collections, 'indexing' => ['shelf_ssi'], 'cardinality' => { 'minimum' => 0 } }
      shelved = described_class.new(SolrDocument.new(document.to_h.merge('shelf_ssi' => 'Vault 2')), Ability.new(nil))

      expect(shelved.shelf).to eq ['Vault 2']
    end

    it 'matches its class when the profile writes the class name with a leading ::' do
      properties['call_number']['available_on'] = { 'class' => ['::CollectionResource'] }

      expect(presenter.profile_property(:call_number)).to be_present
    end

    it 'has no profile entry for a property available only on other classes' do
      properties['shelf_mark'] = { 'available_on' => { 'class' => ['GenericWorkResource'] }, 'indexing' => ['shelf_mark_tesim'] }

      expect(presenter.profile_property(:shelf_mark)).to be_nil
    end

    it 'reads a collection saved under an earlier profile with that profile' do
      allow(Hyrax::FlexibleSchema).to receive(:current_schema_id).and_return(2)
      earlier = properties.deep_merge('call_number' => { 'indexing' => ['call_number_ssim'] })
      allow(Hyrax::FlexibleSchema).to receive(:find_by).with(id: '1').and_return(instance_double(Hyrax::FlexibleSchema, profile: { 'properties' => earlier }))
      saved_earlier = described_class.new(SolrDocument.new(document.to_h.merge('call_number_ssim' => ['MS.0950'])), Ability.new(nil))

      expect(saved_earlier.call_number).to eq ['MS.0950']
    end

    it 'loads an earlier profile once per request, however many collections were saved under it' do
      allow(Hyrax::FlexibleSchema).to receive(:current_schema_id).and_return(2)
      allow(Hyrax::FlexibleSchema).to receive(:find_by).with(id: '1').and_return(instance_double(Hyrax::FlexibleSchema, profile: { 'properties' => properties }))
      2.times { described_class.new(document, Ability.new(nil)).call_number }

      expect(Hyrax::FlexibleSchema).to have_received(:find_by).once
    end

    it "keeps the document's own reading of a property when it has one" do
      properties['date_modified'] = { 'available_on' => on_collections, 'indexing' => ['date_modified_dtsi'], 'data_type' => 'string' }
      dated = described_class.new(SolrDocument.new(document.to_h.merge('date_modified_dtsi' => '2026-10-01T12:00:00Z')), Ability.new(nil))

      expect(dated.date_modified).to eq Date.new(2026, 10, 1)
    end

    context "when the document's own reader finds nothing under the profile's index keys" do
      let(:summarized) do
        properties['abstract'] = { 'available_on' => on_collections, 'indexing' => ['abstract_ssim'], 'data_type' => 'array' }
        described_class.new(SolrDocument.new(document.to_h.merge('abstract_ssim' => ['Maps of the harbor.'])), Ability.new(nil))
      end

      it "reads the property from the profile's index keys" do
        expect(summarized.abstract).to eq ['Maps of the harbor.']
      end

      it 'looks it up by term the same way' do
        expect(summarized[:abstract]).to eq ['Maps of the harbor.']
      end
    end

    it 'looks up through the document a term only an admin set presenter has a reader for' do
      properties['alternative_title'] = { 'available_on' => { 'class' => ['AdminSetResource'] }, 'indexing' => ['alternative_title_tesim'], 'data_type' => 'array' }
      Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a3', 'has_model_ssim' => ['AdminSetResource'], 'schema_version_ssi' => '1'), Ability.new(nil))
      titled = described_class.new(SolrDocument.new(document.to_h.merge('alternative_title_tesim' => ['Harbor papers'])), Ability.new(nil))

      expect(titled[:alternative_title]).to eq ['Harbor papers']
    end

    it "skips a listed field on a collection saved without the profile, even once a flexible collection's reader exists" do
      properties['abstract'] = { 'available_on' => on_collections, 'indexing' => ['abstract_tesim'], 'data_type' => 'array' }
      presenter
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[abstract])
      plain = described_class.new(SolrDocument.new('id' => 'c2', 'has_model_ssim' => ['CollectionResource'],
                                                   'abstract_tesim' => ['Maps of the harbor.']), Ability.new(nil))

      expect(plain.terms_with_values).to be_empty
    end

    context 'when a same-named entry is limited to a context' do
      let(:admin_set) do
        Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a2', 'has_model_ssim' => ['AdminSetResource'], 'schema_version_ssi' => '1',
                                                      'contexts_ssim' => ['closed_context']), Ability.new(nil))
      end

      before do
        classes = %w[CollectionResource AdminSetResource]
        properties['keyword'] = { 'available_on' => { 'class' => classes }, 'indexing' => ['keyword_tesim'] }
        properties['keyword_closed'] = { 'name' => 'keyword', 'available_on' => { 'class' => classes, 'context' => ['closed_context'] },
                                         'indexing' => ['keyword_tesim', 'admin_only'] }
      end

      it 'uses the unscoped entry, since contexts apply to works' do
        expect(presenter.profile_property(:keyword)['indexing']).not_to include('admin_only')
      end

      it "uses the unscoped entry on an admin set that defines that context" do
        expect(admin_set.profile_property(:keyword)['indexing']).not_to include('admin_only')
      end
    end

    it 'never takes a same-named entry that is not available on the collection class' do
      properties['keyword_works'] = { 'name' => 'keyword', 'available_on' => { 'class' => ['GenericWorkResource'] }, 'indexing' => ['keyword_tesim', 'admin_only'] }
      properties['keyword'] = { 'available_on' => { 'class' => ['CollectionResource'] }, 'indexing' => ['keyword_tesim'] }

      expect(presenter.profile_property(:keyword)['indexing']).not_to include('admin_only')
    end

    it 'looks up such a property by term, as the collection page does' do
      expect(presenter[:call_number]).to eq ['MS.0951']
    end
  end

  # TEMPORARY: re-evaluate and remove when samvera/hyrax#7732 is in the bundled Hyrax
  describe '#terms with an app list' do
    let(:document) { SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['CollectionResource']) }
    let(:presenter) { described_class.new(document, Ability.new(nil)) }

    it "leaves Hyrax's terms in place when an app sets no list" do
      expect(presenter.terms).to eq described_class.terms + presenter.compound_terms
    end

    it "replaces a collection page's terms with an app's list, in its order" do
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[abstract creators title])

      expect(presenter.terms).to eq %i[abstract creators title]
    end

    it 'skips a configured field the document has but the presenter cannot read' do
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[title abstract])
      summarized = described_class.new(SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['CollectionResource'],
                                                        'title_tesim' => ['Harbor Records'], 'abstract_tesim' => ['Maps of the harbor.']), Ability.new(nil))

      expect(summarized.terms_with_values).to eq %i[title]
    end

    it 'skips a configured term only the presenter defines when listing terms with values' do
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[title total_viewable_items])
      titled = described_class.new(SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['CollectionResource'],
                                                    'title_tesim' => ['Harbor Records']), Ability.new(nil))

      expect(titled.terms_with_values).to eq %i[title]
    end

    it "leaves an admin set's terms alone" do
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[abstract creators title])
      admin_set = Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a1', 'has_model_ssim' => ['AdminSetResource']), Ability.new(nil))

      expect(admin_set.terms).not_to eq %i[abstract creators title]
    end
  end
end
