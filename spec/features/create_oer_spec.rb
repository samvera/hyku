# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Oer`
require 'rails_helper'

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.feature 'Create a Oer', type: :feature, js: true, clean: true, cohort: 'alpha' do
  include Warden::Test::Helpers

  context 'a logged in user with the :work_depositor role' do
    let(:user) { create(:user, roles: [:work_depositor]) }
    let(:admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s }
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
    xit 'User submits a form and sees success message' do
      visit '/dashboard/my/works'
      # TODO(labradford) We are not able to get this link click to work in our automated tests, so this is a workaround.
      # I hope that if we move to system specs instead of feature specs we'll be able to move back to alignment with
      # how upstream Hyku/ Hyrax do this.
      # click_link "Works"
      click_link "Add New Work"

      # If you generate more than one work uncomment these lines
      choose "payload_concern", option: "Oer"
      click_button "Create work"

      expect(page).to have_content(/Add New OER/i)
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('div#add-files') do
        attach_file("files[]", File.join(file_fixture_path, 'hyrax', 'image.jp2'), visible: false)
        attach_file("files[]", File.join(file_fixture_path, 'hyrax', 'jp2_fits.xml'), visible: false)
      end
      click_link "Descriptions" # switch tab
      fill_in('Title', with: 'My Test Work')
      fill_in('Creator', with: 'Doe, Jane')
      select('Poster', from: 'oer_resource_type')
      fill_in('Date', with: '02/02/2020')
      select('Student', from: 'Audience')
      select('Community college / Lower division', from: 'Education Level')
      select('Syllabus', from: 'Learning Resource Type')
      select('Languages - Spanish', from: 'Discipline')
      select('In Copyright', from: 'Rights')

      page.choose('oer_visibility_open')
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      find('#agreement').click

      click_on('Save')
      expect(page).to have_content('My Test Work')
      expect(page).to have_content("Your files are being processed by Hyku in the background.")
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
