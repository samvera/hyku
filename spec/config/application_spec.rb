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

  describe '.iiif_video_url_builder' do
    subject { described_class.iiif_video_url_builder }
    it { is_expected.to be_a(Proc) }
  end

  describe '.iiif_audio_url_builder' do
    subject { described_class.iiif_audio_url_builder }
    it { is_expected.to be_a(Proc) }
  end

  describe ".cross_tenant_search_url" do
    subject { described_class.cross_tenant_search_url }

    it { is_expected.to start_with("//") }
  end

  describe ".cross_tenant_search_host" do
    subject { described_class.cross_tenant_search_host }

    it { is_expected.to be_present }
    it { is_expected.to be_a(String) }
  end
end
