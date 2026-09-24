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

  describe "#iiif_manifest_presenter" do
    subject(:presenter) { controller.send :iiif_manifest_presenter }

    let(:solr_document) { SolrDocument.new(id: 'work-1', has_model_ssim: ['GenericWork']) }

    before do
      allow(controller).to receive(:search_result_document).and_return(solr_document)
      controller.params = { id: solr_document.id }
    end

    it "builds a Hyrax::IiifManifestPresenter by default" do
      expect(presenter).to be_an_instance_of Hyrax::IiifManifestPresenter
    end

    context "when the controller configures its own presenter class" do
      let(:presenter_class) { Class.new(Hyrax::IiifManifestPresenter) }

      before { allow(described_class).to receive(:iiif_manifest_presenter_class).and_return(presenter_class) }

      it "builds that class" do
        expect(presenter).to be_an_instance_of presenter_class
      end

      it "still sets the hostname, ability and IiifPrint's base_url" do
        expect(presenter.hostname).to eq "test.host"
        expect(presenter.ability).to eq controller.current_ability
        expect(presenter.base_url).to eq "http://test.host"
      end
    end
  end

  describe '#create with a parent_id' do
    let(:parent) { FactoryBot.valkyrie_create(:generic_work_resource, depositor: user.user_key) }

    before { sign_in user }

    it 'allows a child whose type the parent accepts' do
      editable = FactoryBot.valkyrie_create(:generic_work_resource, edit_users: [user])

      post :create, params: { parent_id: editable.id.to_s,
                              generic_work: { title: ['Legitimate child'] } }

      expect(flash[:alert]).to be_blank
      expect(response).not_to redirect_to(root_path)
    end

    it 'does not load the parent resource to run the guard' do
      editable = FactoryBot.valkyrie_create(:generic_work_resource, edit_users: [user])
      allow(Hyrax.query_service).to receive(:find_by).and_call_original

      post :create, params: { parent_id: editable.id.to_s,
                              generic_work: { title: ['Counted child'] } }

      expect(Hyrax.query_service).not_to have_received(:find_by).with(id: editable.id)
    end

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
