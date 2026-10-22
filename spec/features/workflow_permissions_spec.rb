# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflows: embargo, lease, sharing, relationships', type: :feature, js: true, clean: true, flexible: :either do
  let(:admin_user) { create(:admin) }
  let(:work) { FactoryBot.valkyrie_create(:generic_work_resource) }

  before do
    # Default groups may already exist (e.g. created when the admin user is created).
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    login_as admin_user
  end

  # Opens the new Work form the way a depositor does: "Add New Work" opens the work-type
  # modal, then "Create work" for the chosen type. The button only renders for a user who
  # can deposit into an admin set, hence the default admin set.
  def open_new_work_form
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    visit '/dashboard/my/works'
    find('#add-new-work-button').click
    within('#worktypes-to-create') do
      choose 'payload_concern', option: 'GenericWork'
      click_button 'Create work'
    end
  end

  def fill_in_required_metadata(title)
    fill_in 'Title', with: title
    fill_in 'Creator', with: 'Workflow Admin'
    select 'In Copyright', from: 'Rights Statement'
  end

  context 'embargo workflow' do
    it 'allows setting an embargo during work creation' do
      open_new_work_form
      fill_in_required_metadata('Embargoed Work')

      # Visibility is the radio group in the form sidebar; choosing Embargo reveals its date.
      find("input[type='radio'][value='embargo']").click
      fill_in 'generic_work_embargo_release_date', with: Date.current + 1.year
      find('#agreement').click
      click_button 'Save'

      expect(page).to have_content('Embargoed Work')
      expect(page).to have_css('.badge', text: 'Embargo')
    end
  end

  context 'lease workflow' do
    it 'allows setting a lease during work creation' do
      open_new_work_form
      fill_in_required_metadata('Leased Work')

      find("input[type='radio'][value='lease']").click
      fill_in 'generic_work_lease_expiration_date', with: Date.current + 6.months
      find('#agreement').click
      click_button 'Save'

      expect(page).to have_content('Leased Work')
      expect(page).to have_css('.badge', text: 'Lease')
    end
  end

  context 'sharing workflow' do
    let!(:group) { FactoryBot.create(:group, name: 'cataloging_team') }
    it 'offers existing groups to share with on the Sharing tab' do
      visit "/concern/generic_works/#{ERB::Util.url_encode(work.id)}/edit#share"
      expect(page).to have_content 'Add Sharing'
      expect(page.has_select?('new_group_name_skel', with_options: [group.humanized_name])).to be true
    end
  end

  context 'relationships tab' do
    it 'shows the relationships tab on the new work form' do
      open_new_work_form
      expect(page).to have_link('Relationships')
    end
  end

  # Manual Test Plan: "Workflow Roles Page" (/admin/workflow_roles; Hyku override view
  # app/views/hyrax/admin/workflow_roles/index.html.erb).
  context 'Workflow Roles Page' do
    let!(:listed_user) { FactoryBot.create(:user, email: 'betty@example.com', display_name: 'Betty Rubble') }
    let!(:other_user) { FactoryBot.create(:user, email: 'fred@example.com', display_name: 'Fred Stone') }
    let(:approving_role) { 'Default Admin Set - approving (default)' }

    before do
      # The default admin set + permission template seed the Sipity workflow roles.
      admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
      Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id)

      visit '/admin/workflow_roles'
    end

    def assign_approving_role_to_betty
      select 'Betty Rubble', from: 'sipity_workflow_responsibility_user_id'
      select approving_role, from: 'sipity_workflow_responsibility_workflow_role_id'
      click_button 'assign_user_role_save_button'
    end

    def user_roles_search
      find('table.user-workflow-roles-table').ancestor('.dataTables_wrapper').find("input[type='search']")
    end

    # Potential duplicate: spec/features/assign_workflow_to_group_spec.rb:32 (assigns a workflow role to a user; CI-skipped)
    it 'assigns an existing user a specific workflow role with the form' do
      expect(find('tr#betty-example-com td:nth-child(3)')).to have_text(/\ANo roles\z/)

      assign_approving_role_to_betty

      expect(find('tr#betty-example-com td:nth-child(3)')).to have_text(approving_role)
      expect(find('tr#fred-example-com td:nth-child(3)')).to have_text(/\ANo roles\z/)
      agent = Sipity::Agent.find_by!(proxy_for_id: listed_user.id.to_s, proxy_for_type: 'User')
      expect(agent.workflow_responsibilities.map { |r| r.workflow_role.role.name }).to eq(['approving'])
    end

    it 'lists all users in the repository with their workflow roles' do
      within('table.user-workflow-roles-table') do
        expect(page).to have_css('th', text: 'Email')
        expect(page).to have_css('th', text: 'Display Name')
        expect(page).to have_css('th', text: 'Roles')
      end

      [admin_user, listed_user, other_user].each do |user|
        row = find("tr##{user.user_key.parameterize}")
        expect(row.find('td:nth-child(1)')).to have_text(user.user_key)
      end
      expect(find('tr#betty-example-com td:nth-child(2)')).to have_text('Betty Rubble')
      expect(find('tr#fred-example-com td:nth-child(2)')).to have_text('Fred Stone')
    end

    it 'filters the user roles list with its search bar by user or by role' do
      assign_approving_role_to_betty
      expect(find('tr#betty-example-com td:nth-child(3)')).to have_text(approving_role)

      user_roles_search.fill_in(with: 'fred')
      expect(page).to have_css('tr#fred-example-com')
      expect(page).not_to have_css('tr#betty-example-com')

      user_roles_search.fill_in(with: 'approving')
      expect(page).to have_css('tr#betty-example-com')
      expect(page).not_to have_css('tr#fred-example-com')
    end
  end
end
