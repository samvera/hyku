# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyku::Application do
  describe '.html_head_title' do
    subject { described_class.html_head_title }

    it { is_expected.to be_a(String) }
  end

  describe '.user_devise_parameters' do
    subject { described_class.user_devise_parameters }

    it do
      is_expected.to eq([:database_authenticatable,
                         :invitable,
                         :registerable,
                         :recoverable,
                         :rememberable,
                         :trackable,
                         :validatable,
                         :omniauthable,
                         { omniauth_providers: %i[saml openid_connect cas] }])
    end
  end

  describe '.iiif_audio_labels_and_mime_types' do
    subject { described_class.iiif_audio_labels_and_mime_types }
    it { is_expected.to be_a(Hash) }
  end

  describe '.iiif_video_labels_and_mime_types' do
    subject { described_class.iiif_video_labels_and_mime_types }
    it { is_expected.to be_a(Hash) }
  end

  describe '.iiif_av_url_builder' do
    subject { described_class.iiif_av_url_builder }
    it { is_expected.to be_a(Proc) }
  end

  describe '.work_types' do
    subject { described_class.work_types }

    # These are the default
    it { is_expected.to eq([GenericWorkResource, ImageResource, EtdResource, OerResource]) }
  end

  describe 'Hyrax configuration' do
    subject { Hyrax.config }

    its(:file_set_class) { is_expected.to eq(Hyrax::FileSet) }
    its(:admin_set_class) { is_expected.to eq(AdminSetResource) }
    its(:collection_class) { is_expected.to eq(CollectionResource) }
  end

  describe 'Bulkrax configuration' do
    subject { Bulkrax }

    it 'is enabled by default' do
      expect(Hyku.bulkrax_enabled?).to be_truthy
    end

    its(:file_model_class) { is_expected.to eq(Hyrax::FileSet) }
    its(:collection_model_class) { is_expected.to eq(CollectionResource) }
  end
end
