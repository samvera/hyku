# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Oer`
require 'rails_helper'
include Warden::Test::Helpers

# NOTE: If you generated more than one work, you have to set "js: true"

RSpec.feature 'Create a Oer', type: :feature, js: true, clean: true do
  context 'a logged in user' do
    let(:user_attributes) do
      { email: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end
    let!(:admin_group) { Hyrax::Group.create(name: "admin") }
    let!(:registered_group) { Hyrax::Group.create(name: "registered") }
    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
    let(:workflow) do
      Sipity::Workflow.create!(
        active: true,
        name: 'test-workflow',
        permission_template: permission_template
      )
    end

    before do
      # Create a single action that can be taken
      Sipity::WorkflowAction.create!(name: 'submit', workflow: workflow)

      # Grant the user access to deposit into the admin set.
      Hyrax::PermissionTemplateAccess.create!(
        permission_template_id: permission_template.id,
        agent_type: 'user',
        agent_id: user.user_key,
        access: 'deposit'
      )
      login_as user
    end
    scenario do
      visit '/dashboard/works'
      # TODO(labradford) We are not able to get this link click to work in our automated tests, so this is a workaround.
      # I hope that if we move to system specs instead of feature specs we'll be able to move back to alignment with
      # how upstream Hyku/ Hyrax do this.
      # click_link "Works"
      click_link "Add new work"

      # If you generate more than one work uncomment these lines
      choose "payload_concern", option: "Oer"
      click_button "Create work"

      expect(page).to have_content "Add New OER"
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('span#addfiles') do
        attach_file("files[]", Rails.root.join('spec', 'fixtures', 'images', 'image.jp2'), visible: false)
        attach_file("files[]", Rails.root.join('spec', 'fixtures', 'images', 'jp2_fits.xml'), visible: false)
      end
      click_link "Descriptions" # switch tab
      check('agreement')
      fill_in('Title', with: 'My Test Work')
      fill_in('Creator', with: 'Doe, Jane')
      select('Collection', from: 'oer_resource_type')
      fill_in('Date', with: '02/02/2020')
      select('Student', from: 'Audience')
      select('Community college / Lower division', from: 'Education Level')
      select('Syllabus', from: 'Learning Resource Type')
      select('Languages - Spanish', from: 'Discipline')
      select('In Copyright', from: 'Rights Statement')

      # With selenium and the chrome driver, focus remains on the
      # select box. Click outside the box so the next line can't find
      # its element
      find('body').click
      choose('oer_visibility_open')
      # rubocop:disable Metrics/LineLength
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      # rubocop:enable Metrics/LineLength

      click_on('Save')
      expect(page).to have_content('My Test Work')
      expect(page).to have_content "Your files are being processed by Hyku Commons in the background."
    end
    # rubocop:enable RSpec/ExampleLength
  end
end