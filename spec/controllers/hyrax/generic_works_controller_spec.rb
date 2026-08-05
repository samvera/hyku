# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::GenericWorksController do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:generic_work_resource, :with_one_file_set, depositor: user.user_key) }

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

  describe '#create with a parent_id' do
    let(:parent) { FactoryBot.valkyrie_create(:generic_work_resource, depositor: user.user_key) }

    before { sign_in user }

    context 'when the parent accepts no children' do
      before do
        @original = GenericWorkResource.valid_child_concerns
        GenericWorkResource.valid_child_concerns = []
      end

      after { GenericWorkResource.valid_child_concerns = @original }

      it 'refuses the deposit' do
        post :create, params: { parent_id: parent.id.to_s,
                                generic_work: { title: ['Rejected child'] } }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t('hyku.works.errors.parent_not_allowed'))
      end
    end

    it 'refuses a parent the user cannot edit' do
      other = FactoryBot.valkyrie_create(:generic_work_resource,
                                         depositor: FactoryBot.create(:user).user_key)

      post :create, params: { parent_id: other.id.to_s,
                              generic_work: { title: ['Not mine'] } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t('hyku.works.errors.parent_not_allowed'))
    end
  end
end
