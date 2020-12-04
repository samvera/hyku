# frozen_string_literal: true

require 'rails_helper'

# Two users, the user assigning roles and the user to whom a role is assigned
RSpec.describe 'Assign workflow to group', type: :feature, js: true, clean: true do
  include Warden::Test::Helpers
  context 'an admin user' do
    let!(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Wilma Flinstone') }
    let!(:user) { FactoryBot.create(:user, email: 'user@example.com', display_name: 'Betty Rubble') }
    let!(:group) { FactoryBot.create(:group, name: 'Flinstones') }

    let!(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let!(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
    let!(:workflow) do
      Sipity::Workflow.create!(
        active: true,
        name: 'test-workflow',
        permission_template: permission_template
      )
    end

    it 'admin assigns an approving workflow role to a user' do
      login_as admin
      visit '/admin/workflow_roles'
      expect(page).to have_content 'Current User Roles'
      expect(page).to have_content 'Wilma Flinstone'
      expect(find('tr#user-example-com').find('td:nth-child(2)').text).to include('Betty Rubble')
      expect(find('tr#user-example-com').find('td:nth-child(3)').text).to eq('No roles')
      find('#sipity_workflow_responsibility_user_id option', text: "Betty Rubble").click
      # With selenium and the chrome driver, focus remains on the
      # select box. Click outside the box so the next line can find
      # its element
      find('body').click
      find(
        '#sipity_workflow_responsibility_workflow_role_id option',
        text: 'Default Admin Set - approving (default)'
      ).click
      find('#assign_user_role_save_button').click
      expect(find('tr#user-example-com').find('td:nth-child(2)').text).to include('Betty Rubble')
      expect(find('tr#user-example-com').find('td:nth-child(3)').text).to eq('Default Admin Set - approving (default)')
    end

    it 'admin assigns an approving workflow role to a group' do
      group.add_members_by_id(user.id)
      login_as admin
      visit '/admin/workflow_roles'
      expect(page).to have_content 'Current Group Roles'
      expect(find('tr#Flinstones').find('td:nth-child(1)').text).to eq('Flinstones')
      expect(find('tr#Flinstones').find('td:nth-child(2)').text).to eq 'No roles'
      find('#sipity_workflow_responsibility_group_id option', text: "Flinstones").click
      # With selenium and the chrome driver, focus remains on the
      # select box. Click outside the box so the next line can find
      # its element
      find('body').click
      find(
        '#sipity_workflow_responsibility_group_workflow_role_id option',
        text: 'Default Admin Set - approving (default)'
      ).click
      find('#assign_group_role_save_button').click
      expect(find('tr#Flinstones').find('td:nth-child(1)').text).to eq('Flinstones')
      expect(find('tr#Flinstones').find('td:nth-child(2)').text).to eq 'Default Admin Set - approving (default)'
    end
  end
end
