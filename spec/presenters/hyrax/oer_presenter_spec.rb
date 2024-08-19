# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work Oer`
# NOTE: The majority of this spec is coming from the hyrax-iiif_av gem.
# See this file for more info: https://github.com/samvera-labs/hyrax-iiif_av/blob/main/lib/hyrax/iiif_av/spec/shared_specs/displays_iiif_av.rb
require 'rails_helper'

RSpec.describe Hyrax::OerPresenter do
  subject { described_class.new(double, double) }

  let(:solr_document) { SolrDocument.new(attributes) }
  let(:request) { double(host: 'example.org', base_url: 'http://example.org') }
  let(:user_key) { 'a_user_key' }

  let(:attributes) do
    { "id" => '888888',
      "title_tesim" => ['foo', 'bar'],
      "human_readable_type_tesim" => ["OER"],
      "has_model_ssim" => ["Oer"],
      "date_created_tesim" => ['an unformatted date'],
      "depositor_tesim" => user_key }
  end
  let(:ability) { double Ability }
  let(:presenter) { described_class.new(solr_document, ability, request) }

  describe "#model_name" do
    subject { presenter.model_name }

    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe '#iiif_viewer?' do
    subject { presenter.iiif_viewer? }

    let(:id_present) { false }
    let(:representative_presenter) { double('representative', present?: false) }
    let(:image_boolean) { false }
    let(:video_boolean) { false }
    let(:audio_boolean) { false }
    let(:pdf_boolean) { false }
    let(:iiif_enabled) { true }
    let(:file_set_presenter) { Hyrax::FileSetPresenter.new(solr_document, ability) }
    let(:file_set_presenters) { [file_set_presenter] }
    let(:read_permission) { true }

    before do
      allow(presenter).to receive(:representative_id).and_return(id_present)
      allow(presenter).to receive(:representative_presenter).and_return(representative_presenter)
      allow(presenter).to receive(:file_set_presenters).and_return(file_set_presenters)
      allow(file_set_presenter).to receive(:image?).and_return(true)
      allow(ability).to receive(:can?).with(:read, solr_document.id).and_return(read_permission)
      allow(representative_presenter).to receive(:image?).and_return(image_boolean)
      allow(representative_presenter).to receive(:video?).and_return(video_boolean)
      allow(representative_presenter).to receive(:audio?).and_return(audio_boolean)
      allow(representative_presenter).to receive(:pdf?).and_return(pdf_boolean)
      allow(Hyrax.config).to receive(:iiif_image_server?).and_return(iiif_enabled)
    end

    context 'with no representative_id' do
      it { is_expected.to be false }
    end

    context 'with no representative_presenter' do
      let(:id_present) { true }

      it { is_expected.to be false }
    end

    context 'with non-image representative_presenter' do
      let(:id_present) { true }
      let(:representative_presenter) { double('representative', present?: true) }

      it { is_expected.to be false }
    end

    context 'with IIIF image server turned off' do
      let(:id_present) { true }
      let(:representative_presenter) { double('representative', present?: true) }
      let(:image_boolean) { true }
      let(:iiif_enabled) { false }

      it { is_expected.to be false }
    end

    context 'with representative image and IIIF turned on' do
      let(:id_present) { true }
      let(:representative_presenter) { double('representative', present?: true) }
      let(:image_boolean) { true }
      let(:iiif_enabled) { true }

      # We don't have the proper test harness to make this work in light of IIIF Print adjustments.
      xit { is_expected.to be true }

      context "when the user doesn't have permission to view the image" do
        let(:read_permission) { false }

        it { is_expected.to be false }
      end
    end
  end

  describe "#attribute_to_html" do
    let(:renderer) { double('renderer') }

    context 'with an existing field' do
      before do
        allow(Hyrax::Renderers::AttributeRenderer).to receive(:new)
          .with(:title, ['foo', 'bar'], {})
          .and_return(renderer)
      end

      it "calls the AttributeRenderer" do
        expect(renderer).to receive(:render)
        presenter.attribute_to_html(:title)
      end
    end

    context "with a field that doesn't exist" do
      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with('Hyrax::OerPresenter attempted to render restrictions, but no method exists with that name.')
        presenter.attribute_to_html(:restrictions)
      end
    end
  end

  describe "#work_presenters" do
    let(:obj) { valkyrie_create(:oer_resource, :with_file_and_work, depositor: 'somebody') }
    let(:attributes) { obj.to_solr }

    it "filters out members that are file sets" do
      expect(presenter.work_presenters.count).to eq 1
    end
  end

  describe "#manifest" do
    let(:work) { valkyrie_create(:oer_resource, :with_one_file_set, depositor: 'somebody') }
    let(:solr_document) { SolrDocument.new(work.to_solr) }

    describe "#sequence_rendering" do
      subject do
        presenter.sequence_rendering
      end

      it "returns a hash containing the rendering information" do
        work.rendering_ids = [work.members.first.id]
        expect(subject).to be_an Array
      end
    end

    describe 'admin users' do
      let(:user)    { create(:admin) }
      let(:ability) { Ability.new(user) }
      let(:attributes) do
        {
          "read_access_group_ssim" => ["public"],
          'id' => '99999'
        }
      end

      context 'with a new public work' do
        xit 'can feature the work' do
          allow(user).to receive(:can?).with(:create, FeaturedWork).and_return(true)
          expect(presenter.work_featurable?).to be true
          expect(presenter.display_feature_link?).to be true
          expect(presenter.display_unfeature_link?).to be false
        end
      end

      context 'with a featured work' do
        before { FeaturedWork.create(work_id: attributes.fetch('id')) }
        xit 'can unfeature the work' do
          expect(presenter.work_featurable?).to be true
          expect(presenter.display_feature_link?).to be false
          expect(presenter.display_unfeature_link?).to be true
        end
      end

      describe "#editor?" do
        subject { presenter.editor? }

        it { is_expected.to be true }
      end
    end

    describe "#manifest_metadata" do
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
  end

  describe "#show_deposit_for?" do
    subject { presenter }

    context "when user has depositable collections" do
      let(:user_collections) { double }

      it "returns true" do
        expect(subject.show_deposit_for?(collections: user_collections)).to be true
      end
    end

    context "when user does not have depositable collections" do
      let(:user_collections) { nil }

      context "and user can create a collection resource" do
        before do
          allow(ability).to receive(:can?).with(:create_any, CollectionResource).and_return(true)
        end

        it "returns true" do
          expect(subject.show_deposit_for?(collections: user_collections)).to be true
        end
      end

      context "and user can NOT create a collection resource" do
        before do
          allow(ability).to receive(:can?).with(:create_any, CollectionResource).and_return(false)
        end

        it "returns false" do
          expect(subject.show_deposit_for?(collections: user_collections)).to be false
        end
      end
    end
  end

  describe '#iiif_viewer' do
    subject { presenter.iiif_viewer }

    let(:representative_presenter) { instance_double('Hyrax::FileSetPresenter', present?: true) }
    let(:image_boolean) { false }
    let(:audio_boolean) { false }
    let(:video_boolean) { false }

    before do
      allow(presenter).to receive(:representative_presenter).and_return(representative_presenter)
      allow(representative_presenter).to receive(:image?).and_return(image_boolean)
      allow(representative_presenter).to receive(:audio?).and_return(audio_boolean)
      allow(representative_presenter).to receive(:video?).and_return(video_boolean)
    end

    it 'defaults to universal viewer' do
      expect(subject).to be :universal_viewer
    end
  end
end
