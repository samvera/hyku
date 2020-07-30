# frozen_string_literal: true

RSpec.describe Hyku::WorkShowPresenter do
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
