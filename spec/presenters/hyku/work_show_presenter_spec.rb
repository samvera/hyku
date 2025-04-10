# frozen_string_literal: true

RSpec.describe Hyku::WorkShowPresenter do
  let(:work) { FactoryBot.valkyrie_create(:generic_work_resource, :with_one_file_set) }
  let(:document) { work.to_solr }
  let(:solr_document) { SolrDocument.new(document) }
  let(:request) { double(base_url: 'http://test.host', host: 'http://test.host') }
  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability, request) }
  let(:default_pdf_viewer_value) { Flipflop::FeatureSet.current.feature(:default_pdf_viewer).default }

  describe "#manifest_url" do
    subject { presenter.manifest_url }

    let(:document) { { "has_model_ssim" => ['GenericWork'], 'id' => '99' } }

    it { is_expected.to eq 'http://test.host/concern/generic_works/99/manifest' }
  end

  describe "#iiif_viewer?" do
    subject { presenter.iiif_viewer? }

    before do
      allow(solr_document).to receive(:representative_id).and_return(solr_document.member_ids.first)
      allow(ability).to receive(:can?).and_return true
      allow_any_instance_of(Hyrax::IiifAv::IiifFileSetPresenter).to receive(:image?).and_return false
      allow_any_instance_of(Hyrax::IiifAv::IiifFileSetPresenter).to receive(:pdf?).and_return false
      allow_any_instance_of(Hyrax::IiifAv::IiifFileSetPresenter).to receive(:video?).and_return false
      allow_any_instance_of(Hyrax::IiifAv::IiifFileSetPresenter).to receive(:audio?).and_return false
    end

    context 'method owner' do
      # I was noticing load logic issues, so I'm adding this spec for verification
      subject { presenter.method(:iiif_viewer?).owner }

      it { is_expected.to eq(IiifPrint::TenantConfig::WorkShowPresenterDecorator) }
    end

    context "for a PDF file" do
      let!(:test_strategy) { Flipflop::FeatureSet.current.test! }

      before { allow_any_instance_of(Hyrax::IiifAv::IiifFileSetPresenter).to receive(:pdf?).and_return true }
      # Return state of the tenant to the default after test suite
      after { test_strategy.switch!(:default_pdf_viewer, default_pdf_viewer_value) }

      context 'when the tenant is not configured to use IIIF Print' do
        before { test_strategy.switch!(:default_pdf_viewer, true) }

        it { is_expected.to be false }
      end

      context 'when the tenant is configured to use IIIF Print' do
        before { test_strategy.switch!(:default_pdf_viewer, false) }

        it { is_expected.to be true }
      end
    end

    context "for an audio file" do
      before do
        allow_any_instance_of(Hyrax::IiifAv::IiifFileSetPresenter).to receive(:audio?).and_return true
      end

      it { is_expected.to be true }
    end

    context "for an image file" do
      before do
        allow_any_instance_of(Hyrax::IiifAv::IiifFileSetPresenter).to receive(:image?).and_return true
      end

      it { is_expected.to be true }
    end

    context "for a video file" do
      before do
        allow_any_instance_of(Hyrax::IiifAv::IiifFileSetPresenter).to receive(:video?).and_return true
      end

      it { is_expected.to be true }
    end
  end

  context "when the work has valid doi and isbns" do
    # the values are set in generic_work_resource factory
    describe "#doi" do
      it "extracts the DOI from the identifiers" do
        expect(presenter.doi).to eq('10.1038/nphys1170')
      end
    end

    describe "#isbns" do
      it "extracts ISBNs from the identifiers" do
        expect(presenter.isbns)
          .to match_array(%w[978-83-7659-303-6 978-3-540-49698-4 9790879392788
                             3-921099-34-X 3-540-49698-x 0-19-852663-6])
      end
    end
  end

  context "when the identifier is nil" do
    let(:document) do
      { "identifier_tesim" => nil }
    end

    describe "#doi" do
      it "is nil" do
        expect(presenter.doi).to be_nil
      end
    end

    describe "#isbns" do
      it "is nil" do
        expect(presenter.isbns).to be_nil
      end
    end
  end

  context "when the work has a doi only" do
    let(:document) do
      { "identifier_tesim" => ['10.1038/nphys1170'] }
    end

    describe "#isbns" do
      it "is empty" do
        expect(presenter.isbns).to be_empty
      end
    end
  end

  context "when the work has isbn(s) only" do
    let(:document) do
      { "identifier_tesim" => ['ISBN:978-83-7659-303-6'] }
    end

    describe "#doi" do
      it "is empty" do
        expect(presenter.doi).to be_empty
      end
    end
  end

  context "when the work's identifiers are not valid doi or isbns" do
    # FOR CONSIDERATION: validate format when a user adds an identifier?
    let(:document) do
      { "identifier_tesim" => %w[3207/2959859860 svnklvw24 0470841559.ch1] }
    end

    describe "#doi" do
      it "is empty" do
        expect(presenter.doi).to be_empty
      end
    end

    describe "#isbns" do
      it "is empty" do
        expect(presenter.isbns).to be_empty
      end
    end

    describe "#parent_works" do
      let(:public_doc) { double(SolrDocument, public?: true) }
      let(:non_public_doc) { double(SolrDocument, public?: false) }
      let(:parent_docs) { [public_doc, non_public_doc] }
      let(:current_user) { double(User, ability: double) }

      before do
        allow(solr_document).to receive(:load_parent_docs).and_return(parent_docs)
      end

      it 'returns the parent works of the solr document' do
        parent_docs.each do |doc|
          allow(doc).to receive(:public?).and_return(true) # Assumes all parent docs are public
        end

        expect(presenter.parent_works).to eq(parent_docs)
      end

      context 'when a public doc is not public' do
        it 'excludes non-public documents' do
          allow(non_public_doc).to receive(:public?).and_return(false)

          expect(presenter.parent_works).to eq([public_doc])
        end
      end

      context 'with a current user and their ability' do
        it 'filters based on user ability' do
          allow(current_user.ability).to receive(:can?).with(:read, public_doc).and_return(false)
          allow(current_user.ability).to receive(:can?).with(:read, non_public_doc).and_return(true)

          expect(presenter.parent_works(current_user)).to eq([non_public_doc])
        end
      end
    end
  end
end
