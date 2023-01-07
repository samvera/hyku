# frozen_string_literal: true

# NOTE: If want to run spec in browser, you have to set "js: true"
RSpec.describe 'Creating a new Work', type: :feature, clean: true do
  let(:user) { create(:user, roles: [:work_depositor]) }

  before do
    FactoryBot.create(:registered_group)
    FactoryBot.create(:admin_group)
    FactoryBot.create(:editors_group)
    FactoryBot.create(:depositors_group)
    AdminSet.find_or_create_default_admin_set_id
    login_as user, scope: :user
  end

  it 'creates the work' do
    visit '/'
    click_link "Share Your Work"
    expect(page).to have_button "Create work"
  end
end
