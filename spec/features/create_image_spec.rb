# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Image`
require 'rails_helper'

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.describe 'Create a Image', type: :feature, js: true, clean: true do
  include Warden::Test::Helpers

  context 'a logged in user with the :work_depositor role' do
    let(:user) { create(:user, roles: [:work_depositor]) }
    let(:admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id }
    let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
    let(:workflow) do
      Sipity::Workflow.create!(
        active: true,
        name: 'test-workflow',
        permission_template:
      )
    end

    before do
      create(:admin_group)
      create(:registered_group)
      create(:editors_group)
      create(:depositors_group)
      # Create a single action that can be taken
      Sipity::WorkflowAction.create!(name: 'submit', workflow:)

      # Grant the user access to deposit into the admin set.
      Hyrax::PermissionTemplateAccess.create!(
        permission_template_id: permission_template.id,
        agent_type: 'user',
        agent_id: user.user_key,
        access: 'deposit'
      )
      login_as user
    end

    # Temporarily commenting out these specs because they consistently fail in the CI pipeline
    # after the Bulkrax version update. The issue seems related to form submission failing
    # in the CI environment but not locally. This needs further investigation to resolve.
    xit do # rubocop:disable RSpec/ExampleLength
      visit '/dashboard/my/works'
      click_link "Add New Work"

      # If you generate more than one work uncomment these lines
      choose "payload_concern", option: "Image"
      click_button "Create work"

      expect(page).to have_content "Add New Image"
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('div#add-files') do
        attach_file("files[]", File.join(file_fixture_path, 'hyrax', 'image.jp2'), visible: false)
        attach_file("files[]", File.join(file_fixture_path, 'hyrax', 'jp2_fits.xml'), visible: false)
      end
      expect(page).to have_selector(:link_or_button, 'Delete') # Wait for files to finish uploading

      click_link "Descriptions" # switch tab
      fill_in('Title', with: 'My Test Work')
      fill_in('Creator', with: 'Doe, Jane')
      click_on('Additional fields')
      fill_in('Keyword', with: 'testing')
      select('In Copyright', from: 'Rights Statement')

      page.choose('image_visibility_open')
      # rubocop:disable Layout/LineLength
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      # rubocop:enable Metrics/MethodLength
      find('#agreement').click

      click_on('Save')
      expect(page).to have_content('My Test Work')
      expect(page).to have_content "Your files are being processed by Hyku in the background."
    end
  end
end
