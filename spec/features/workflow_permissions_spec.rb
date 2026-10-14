# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflows: embargo, lease, sharing, relationships', type: :feature, js: true, clean: true do
  let(:admin_user) { create(:admin) }
  let(:work) { FactoryBot.valkyrie_create(:generic_work_resource) }

  before do
    FactoryBot.create(:admin_group)
    login_as admin_user
  end

  context 'embargo workflow' do
    it 'allows setting an embargo during work creation' do
      visit '/dashboard/my/works'
      click_link 'Add New Work'
      fill_in('Title', with: 'Embargoed Work')
      fill_in('Creator', with: 'Embargo Admin')
      click_link('Visibility')
      choose('Embargo')
      fill_in('embargo_release_date', with: (Date.today + 1.year).strftime('%Y-%m-%d'))
      find('#agreement').click
      click_on('Save')
      expect(page).to have_content('Embargoed Work')
      expect(page).to have_content('Embargo')
    end
  end

  context 'lease workflow' do
    it 'allows setting a lease during work creation' do
      visit '/dashboard/my/works'
      click_link 'Add New Work'
      fill_in('Title', with: 'Leased Work')
      fill_in('Creator', with: 'Lease Admin')
      click_link('Visibility')
      choose('Lease')
      fill_in('lease_expiration_date', with: (Date.today + 6.months).strftime('%Y-%m-%d'))
      find('#agreement').click
      click_on('Save')
      expect(page).to have_content('Leased Work')
      expect(page).to have_content('Lease')
    end
  end

  context 'sharing workflow' do
    let!(:group) { FactoryBot.create(:group, name: 'dummy') }
    it 'allows sharing a work with a group' do
      visit "/concern/generic_works/#{ERB::Util.url_encode(work.id)}/edit#share"
      expect(page).to have_content 'Add Sharing'
      expect(page.has_select?('new_group_name_skel', with_options: [group.humanized_name])).to be true
    end
  end

  context 'relationships tab' do
    it 'shows the relationships tab on the new work form' do
      visit '/dashboard/my/works'
      click_link 'Add New Work'
      expect(page).to have_content('Relationships')
    end
  end

  # Covers the "Workflow Roles Page" manual test plan (commented at the bottom of this file):
  # the admin page at /admin/workflow_roles (hyrax.admin_workflow_roles_path) where an admin
  # assigns workflow roles to users and reviews who currently holds which roles.
  # Selectors/labels are grounded in the Hyku override view
  # (app/views/hyrax/admin/workflow_roles/index.html.erb), config/locales/hyrax.en.yml, and the
  # existing spec/features/assign_workflow_to_group_spec.rb.
  context 'Workflow Roles Page' do
    # A user (other than the admin) that should appear in the "Current User Roles" listing and
    # in the assign-role form's user dropdown.
    let!(:listed_user) do
      FactoryBot.create(:user, email: 'betty@example.com', display_name: 'Betty Rubble')
    end

    before do
      # Groups referenced by the workflow-roles page / admin set seeding.
      FactoryBot.create(:registered_group)
      FactoryBot.create(:editors_group)
      FactoryBot.create(:depositors_group)

      # Seed the default admin set + permission template so Sipity workflow roles exist and the
      # role dropdown is populated (see assign_workflow_to_group_spec.rb).
      admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
      Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id)

      visit '/admin/workflow_roles'
    end

    it 'shows a form to assign an existing user a specific workflow role' do
      expect(page).to have_content('Assign Role to User')

      # Select an existing user...
      expect(
        page.has_select?('sipity_workflow_responsibility_user_id', with_options: ['Betty Rubble'])
      ).to be true

      # ...and a specific workflow role (populated from the seeded default admin set).
      expect(
        page.has_select?(
          'sipity_workflow_responsibility_workflow_role_id',
          with_options: ['Default Admin Set - approving (default)']
        )
      ).to be true

      expect(page).to have_selector('#assign_user_role_save_button')
    end

    it 'lists all users in the repository with their corresponding workflow roles' do
      expect(page).to have_content('Current User Roles')

      within('table.user-workflow-roles-table') do
        expect(page).to have_content('Email')
        expect(page).to have_content('Display Name')
        expect(page).to have_content('Roles')
        expect(page).to have_content('Betty Rubble')
        expect(page).to have_content('betty@example.com')
      end

      # A user with no assigned workflow roles is listed with "No roles".
      expect(find("tr##{listed_user.user_key.parameterize}")).to have_content('No roles')
    end

    it 'provides a search bar to search for specific users or roles' do
      # The listing tables carry the `datatable` class, and DataTables renders a search input
      # for each of them.
      expect(page).to have_selector('table.user-workflow-roles-table.datatable')
      expect(page).to have_selector("input[type='search']", minimum: 1)
    end
  end
end

# ## Workflow Roles Page
# [Back to TOC](#table-of-contents)

# ![image59](https://github.com/samvera/hyku/assets/19597776/27323704-0f9f-48b9-b2dc-76d3ce0d43ee)

# ### As an admin:

# - [ ] I can see a form to select an existing user and assign them a specific workflow role
# - [ ] I can see a list of all users within a repository and their corresponding workflow roles
#   - [ ] I can see a search bar to search for specific users or roles