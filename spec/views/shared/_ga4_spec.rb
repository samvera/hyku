# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_ga4', type: :view do
  let(:account) { create(:account) }

  before do
    allow(view).to receive(:current_account).and_return(account)
    # Mock the account's google_analytics_id method with a valid GA4 format
    allow(account).to receive(:google_analytics_id).and_return('G-ABCDE12345')
    stub_const('ENV', ENV.to_hash.merge(
      'GOOGLE_ANALYTICS_ID' => 'ENV_GA_ID',
      'HYRAX_ANALYTICS' => 'true'
    ))
  end

  it 'includes the analytics-tenant meta tag with tenant ID' do
    render

    expect(rendered).to include(%(<meta name="analytics-tenant" content="#{account.tenant}">))
  end

  it 'includes the analytics-provider meta tag' do
    render

    expect(rendered).to include('<meta name="analytics-provider" content="ga4">')
  end

  it 'includes Google Analytics script with correct ID' do
    render

    expect(rendered).to include('https://www.googletagmanager.com/gtag/js?id=G-ABCDE12345')
    expect(rendered).to include("gtag('config', 'G-ABCDE12345'")
  end

  context 'when current_account is nil' do
    before do
      allow(view).to receive(:current_account).and_return(nil)
      stub_const('ENV', ENV.to_hash.merge('HYRAX_ANALYTICS' => 'true'))
    end

    it 'uses default tenant ID' do
      render

      expect(rendered).to include('<meta name="analytics-tenant" content="default">')
    end
  end

  context 'when tenant is not a standard UUID' do
    # Use a valid tenant ID that passes validation - 'public' is allowed by the model
    let(:account) { build(:account, tenant: 'public') }

    before do
      account.save!
      allow(view).to receive(:current_account).and_return(account)
      allow(account).to receive(:google_analytics_id).and_return('G-ABCDE12345')
      stub_const('ENV', ENV.to_hash.merge('HYRAX_ANALYTICS' => 'true'))
    end

    it 'uses the actual tenant ID' do
      render

      expect(rendered).to include('<meta name="analytics-tenant" content="public">')
    end
  end
end
