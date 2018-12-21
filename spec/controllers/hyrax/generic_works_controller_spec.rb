RSpec.describe Hyrax::GenericWorksController do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.create(:work_with_one_file, user: user) }
  let(:file_set) { work.ordered_members.to_a.first }

  before do
    Hydra::Works::AddFileToFileSet.call(file_set,
                                        fixture_file('images/world.png'),
                                        :original_file)
  end

  describe '#manifest' do
    let(:manifest_factory) { double(to_h: { test: 'manifest' }) }

    before do
      sign_in user
      allow(IIIFManifest::ManifestFactory).to receive(:new)
        .with(Hyku::ManifestEnabledWorkShowPresenter)
        .and_return(manifest_factory)
    end

    it "produces a manifest" do
      get :manifest, params: { id: work, format: :json }
      expect(response.body).to eq "{\"test\":\"manifest\"}"
    end
  end

  describe "#presenter" do
    let(:solr_document) { SolrDocument.new(FactoryBot.create(:generic_work).to_solr) }

    before do
      allow(controller).to receive(:curation_concern_from_search_results).and_return(solr_document)
    end

    subject { controller.send :presenter }

    it "initializes a presenter" do
      expect(subject).to be_kind_of Hyku::ManifestEnabledWorkShowPresenter
      expect(subject.manifest_url).to eq "http://test.host/concern/generic_works/#{solr_document.id}/manifest"
    end
  end
end
