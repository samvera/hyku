# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_ga4', type: :view do
  let(:account) { create(:account) }

  before do
    allow(view).to receive(:current_account).and_return(account)
    allow(Hyrax::Analytics.config).to receive(:analytics_id).and_return('GA_MEASUREMENT_ID')
    stub_const('ENV', ENV.to_hash.merge('GOOGLE_ANALYTICS_ID' => 'ENV_GA_ID'))
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

    expect(rendered).to include('https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID')
    expect(rendered).to include("gtag('config', 'GA_MEASUREMENT_ID')")
  end

  context 'when current_account is nil' do
    before do
      allow(view).to receive(:current_account).and_return(nil)
    end

    it 'uses default tenant ID' do
      render

      expect(rendered).to include('<meta name="analytics-tenant" content="default">')
    end
  end

  context 'when tenant is not a standard UUID' do
    let(:account) { build(:account, tenant: 'public') }  # 'public' is allowed by validation

    before do
      account.save!
      allow(view).to receive(:current_account).and_return(account)
    end

    it 'uses the actual tenant ID' do
      render

      expect(rendered).to include('<meta name="analytics-tenant" content="public">')
    end
  end
end
