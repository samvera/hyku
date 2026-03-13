# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::GenericWorksController do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:generic_work_resource, :with_one_file_set, depositor: user.user_key) }

  it "includes Hyrax::IiifAv::ControllerBehavior" do
    expect(described_class.include?(Hyrax::IiifAv::ControllerBehavior)).to be true
  end

  describe "#presenter" do
    subject { controller.send :presenter }

    let(:solr_document) { SolrDocument.new(work.to_solr) }

    before do
      allow(controller).to receive(:search_result_document).and_return(solr_document)
    end

    it "initializes a presenter" do
      expect(subject).to be_kind_of Hyku::WorkShowPresenter
      expect(subject.manifest_url).to eq "http://test.host/concern/generic_works/#{solr_document.id}/manifest"

      get :manifest, params: { id: solr_document.id }
      expect(response.status).to eq(200)
    end
  end
end
