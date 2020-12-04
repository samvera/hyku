# frozen_string_literal: true

# NOTE: If want to run spec in browser, you have to set "js: true"
RSpec.describe 'Creating a new Work', type: :feature, clean: true do
  let(:user) { create(:user) }
  let!(:admin_group) { Hyrax::Group.create(name: "admin") }
  let!(:registered_group) { Hyrax::Group.create(name: "registered") }

  before do
    AdminSet.find_or_create_default_admin_set_id
    login_as user, scope: :user
  end

  it 'creates the work' do
    visit '/'
    click_link "Share Your Work"
    expect(page).to have_button "Create work"
  end
end
