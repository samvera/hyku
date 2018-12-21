RSpec.describe Hyku::ManifestEnabledWorkShowPresenter do
  let(:work) { FactoryBot.create(:work_with_one_file) }
  let(:document) { work.to_solr }
  let(:solr_document) { SolrDocument.new(document) }
  let(:request) { double(base_url: 'http://test.host', host: 'http://test.host') }
  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability, request) }

  describe "#manifest_url" do
    subject { presenter.manifest_url }

    let(:document) { { "has_model_ssim" => ['GenericWork'], 'id' => '99' } }

    it { is_expected.to eq 'http://test.host/concern/generic_works/99/manifest' }
  end

  describe "representative_presenter" do
    subject do
      presenter.representative_presenter
    end

    before do
      work.representative_id = work.file_sets.first.id
    end

    it "returns a presenter" do
      expect(subject).to be_kind_of Hyku::FileSetPresenter
    end
  end

  describe "#sequence rendering" do
    subject do
      presenter.sequence_rendering
    end

    before do
      Hydra::Works::AddFileToFileSet.call(work.file_sets.first,
                                          fixture_file('images/world.png'), :original_file)
    end

    it "returns a hash containing the rendering information" do
      work.rendering_ids = [work.file_sets.first.id]
      expect(subject).to be_an Array
    end
  end

  describe "#manifest metadata" do
    subject do
      presenter.manifest_metadata
    end

    before do
      work.title = ['Test title', 'Another test title']
    end

    it "returns an array of metadata values" do
      expect(subject[0]['label']).to eq('Title')
      expect(subject[0]['value']).to include('Test title', 'Another test title')
    end
  end

  context "when the work has valid doi and isbns" do
    # the values are set in generic_works factory
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
  end
end
