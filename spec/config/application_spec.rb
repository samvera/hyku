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
end
