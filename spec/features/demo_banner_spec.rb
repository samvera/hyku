# frozen_string_literal: true

RSpec.describe 'Demo environment banner', type: :feature do
  let(:account) do
    FactoryBot.create(:account, :public_schema, :public_demo_tenant,
                      last_reset_at: Time.zone.parse('2026-07-05 08:00'))
  end

  before do
    allow(Account).to receive(:from_request).and_return(account)
  end

  it 'appears on the home page of a public demo tenant' do
    visit '/'
    expect(page).to have_css('#demo-banner')
    expect(page).to have_content('Demo environment')
    expect(page).to have_content("v#{Hyku::VERSION}")
    expect(page).to have_content('Last reset')
  end

  it 'appears on the sign in page' do
    visit '/users/sign_in'
    expect(page).to have_css('#demo-banner')
  end

  context 'on a regular tenant' do
    let(:account) { FactoryBot.create(:account, :public_schema) }

    it 'does not appear' do
      visit '/'
      expect(page).not_to have_css('#demo-banner')
    end
  end
end
