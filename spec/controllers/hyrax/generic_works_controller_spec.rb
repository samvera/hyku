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

  describe "#manifest cache headers" do
    let(:solr_document) { SolrDocument.new(id: 'work-1', has_model_ssim: ['GenericWork']) }
    let(:signed_in) { false }

    before do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(controller).to receive(:search_result_document).and_return(solr_document)
      allow(::Ability).to receive(:new).and_call_original
      allow(::Ability).to receive(:new).with(nil).and_return(instance_double(Ability, can?: anyone_may_read))
      allow(controller).to receive(:iiif_manifest_builder).and_return(instance_double(Hyrax::ManifestBuilderService, manifest_for: {}))
      allow(Hyrax::IiifManifestPresenter).to receive(:new).and_call_original
      sign_in user if signed_in
      get :manifest, params: { id: solr_document.id }, format: :json
    end

    context "for an anonymous visitor and a work anyone may read" do
      let(:anyone_may_read) { true }

      it "lets shared caches keep the manifest, apart from signed-in visitors" do
        expect(response.headers['Cache-Control']).to include('public', 'max-age=3600')
        expect(response.headers['ETag']).to be_present
        expect(response.headers['Vary']).to include('Cookie')
      end

      it "builds the manifest presenter once" do
        expect(Hyrax::IiifManifestPresenter).to have_received(:new).once
      end

      it "changes the ETag when the manifest's version does, such as when a child work changes" do
        etag = response.headers['ETag']
        allow(Hyrax::IiifManifestPresenter).to receive(:new).and_wrap_original do |original, *args|
          original.call(*args).tap { |presenter| allow(presenter).to receive(:version).and_return('changed') }
        end
        get :manifest, params: { id: solr_document.id }, format: :json

        expect(response.headers['ETag']).not_to eq etag
      end
    end

    context "for a signed-in user and a work anyone may read" do
      let(:anyone_may_read) { true }
      let(:signed_in) { true }

      it "does not let the manifest be stored, since it can list pages only that user may read" do
        expect(response.headers['Cache-Control']).to include('no-store')
        expect(response.headers['ETag']).to be_blank
      end
    end

    context "for an anonymous visitor and a work only some users may read" do
      let(:anyone_may_read) { false }

      it "does not let the manifest be stored" do
        expect(response.headers['Cache-Control']).to include('no-store')
        expect(response.headers['ETag']).to be_blank
      end
    end
  end

  describe "#iiif_manifest_builder" do
    subject(:builder) { controller.send :iiif_manifest_builder }

    let(:solr_document) { SolrDocument.new(id: 'work-1', has_model_ssim: ['GenericWork']) }
    let(:anyone_may_read) { true }

    before do
      allow(Flipflop).to receive(:cache_work_iiif_manifest?).and_return(true)
      allow(controller).to receive(:search_result_document).and_return(solr_document)
      allow(::Ability).to receive(:new).and_call_original
      allow(::Ability).to receive(:new).with(nil).and_return(instance_double(Ability, can?: anyone_may_read))
      controller.params = { id: solr_document.id }
    end

    it "caches an anonymous visitor's manifest of a work anyone may read" do
      expect(builder).to be_a Hyrax::CachingIiifManifestBuilder
    end

    context "for a signed-in user" do
      before { allow(controller).to receive(:current_user).and_return(build(:user)) }

      it("does not cache the manifest") { expect(builder).to be_an_instance_of Hyrax::ManifestBuilderService }
    end

    context "for a work only some users may read" do
      let(:anyone_may_read) { false }

      it("does not cache the manifest") { expect(builder).to be_an_instance_of Hyrax::ManifestBuilderService }
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

    it "leaves file set metadata off its pages by default" do
      expect(presenter.iiif_file_set_metadata).to be false
    end

    context "when the configured presenter class has no file set metadata option" do
      let(:presenter_class) do
        Class.new do
          attr_accessor :hostname, :ability, :base_url

          def initialize(_document); end
        end
      end

      before { allow(described_class).to receive(:iiif_manifest_presenter_class).and_return(presenter_class) }

      it "still builds it" do
        expect(presenter).to be_an_instance_of presenter_class
      end
    end

    context "when the controller opts in to file set metadata" do
      before { allow(described_class).to receive(:iiif_file_set_metadata).and_return(true) }

      it "tells the presenter" do
        expect(presenter.iiif_file_set_metadata).to be true
      end
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
