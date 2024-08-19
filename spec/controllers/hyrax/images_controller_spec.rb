# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Image`
# and copied liberally from the generic work spec
require 'rails_helper'

RSpec.describe Hyrax::ImagesController do
  let(:image_resource) { FactoryBot.valkyrie_create(:image_resource, :with_one_file_set, depositor: 'somebody') }

  describe "#presenter" do
    subject { controller.send :presenter }

    let(:solr_document) { SolrDocument.new(image_resource.to_solr) }

    before do
      allow(controller).to receive(:search_result_document).and_return(solr_document)
    end

    it "initializes a presenter" do
      expect(subject).to be_kind_of Hyku::WorkShowPresenter
      expect(subject.manifest_url).to eq "http://test.host/concern/images/#{solr_document.id}/manifest"

      get :manifest, params: { id: solr_document.id }
      expect(response.status).to eq(200)
    end
  end

  context 'with theming' do
    it { is_expected.to use_around_action(:inject_show_theme_views) }
  end
end
