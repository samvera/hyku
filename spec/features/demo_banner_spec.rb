# frozen_string_literal: true

RSpec.describe 'Demo environment banner', type: :feature do
  let(:account) do
    FactoryBot.create(:demo_account, last_reset_at: Time.zone.parse('2026-07-05 08:00'))
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
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
    let(:account) { FactoryBot.create(:account) }

    it 'does not appear' do
      visit '/'
      expect(page).not_to have_css('#demo-banner')
    end
  end
end
