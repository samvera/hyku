# Generated via
#  `rails generate hyrax:work Image`
include Warden::Test::Helpers

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.describe 'Create a Image', :clean, js: true do
  context 'a logged in user' do
    let(:user) { create(:user) }

    before do
      AdminSet.find_or_create_default_admin_set_id
      login_as user, scope: :user
    end

    it do
      visit '/dashboard'
      click_link "Works"
      click_link "Add new work"

      # If you generate more than one work uncomment these lines
      choose "payload_concern", option: "Image"
      click_button "Create work"
    end
  end
end
