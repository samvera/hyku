RSpec.describe Hyku::ManifestEnabledWorkShowPresenter do
  let(:document) { { "has_model_ssim" => ['GenericWork'], 'id' => '99' } }
  let(:solr_document) { SolrDocument.new(document) }
  let(:request) { double(base_url: 'http://test.host') }
  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability, request) }

  describe "#manifest_url" do
    subject { presenter.manifest_url }
    it { is_expected.to eq 'http://test.host/concern/generic_works/99/manifest' }
  end

  describe "representative_presenter" do
    subject do
      presenter.representative_presenter
    end

    let(:work) { FactoryGirl.create(:work_with_one_file) }
    let(:document) { work.to_solr }

    before do
      work.representative_id = work.file_sets.first.id
    end
    it "returns a presenter" do
      expect(subject).to be_kind_of Hyku::FileSetPresenter
    end
  end

  describe "manifest_extras" do
    subject do
      presenter.manifest_extras
    end

    let(:work) { FactoryGirl.create(:work_with_one_file) }
    let(:document) { work.to_solr }
    let(:solr_document) { SolrDocument.new(document) }
    let(:presenter) { described_class.new(solr_document, ability, request) }

    before do
      Hydra::Works::AddFileToFileSet.call(work.file_sets.first,
                                            fixture_file('images/world.png'), :original_file)
    end

    it "returns a hash containing the rendering information" do
      work.rendering_ids = [work.file_sets.first.id]
      expect(subject).to include(:sequence_rendering)
    end
  end
end
