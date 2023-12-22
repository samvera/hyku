# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::GenericWorksController do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.create(:work_with_one_file, user:) }
  let(:file_set) { work.ordered_members.to_a.first }

  before do
    Hydra::Works::AddFileToFileSet.call(file_set,
                                        fixture_file_upload('images/world.png'),
                                        :original_file)
  end

  it "includes Hyrax::IiifAv::ControllerBehavior" do
    expect(described_class.include?(Hyrax::IiifAv::ControllerBehavior)).to be true
  end

  describe "#presenter" do
    subject { controller.send :presenter }

    let(:solr_document) { SolrDocument.new(FactoryBot.create(:generic_work).to_solr) }

    before do
      allow(controller).to receive(:search_result_document).and_return(solr_document)
    end

    it "initializes a presenter" do
      expect(subject).to be_kind_of Hyku::WorkShowPresenter
      expect(subject.manifest_url).to eq "http://test.host/concern/generic_works/#{solr_document.id}/manifest"
    end
  end
end
