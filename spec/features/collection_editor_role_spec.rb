# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection editor role can be assigned to Groups and Users', type: :feature, js: true, clean: true do
  context 'a user assigned to a group' do
    let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Jenny Admin') }
    let(:user) { FactoryBot.create(:user, display_name: "Jane Quest") }
    let(:user_ability) { ::Ability.new(user) }
    let!(:group) { FactoryBot.create(:group, name: "Pirate Studies") }
    let!(:role) { FactoryBot.create(:role, name: "Collection Editor") }

    it 'receives the privileges of the group' do
      expect(user_ability.collection_editor?).to eq false
      expect(group.members.include?(user)).to eq false
      expect(role.name).to eq "Collection Editor"
      expect(role.groups.include?(group)).to eq false
      expect(group.roles.include?(role)).to eq false
      # Assign Role to the Group
      group.roles << role
      expect(role.groups.include?(group)).to eq true
      expect(group.roles.include?(role)).to eq true
      # Add user to the group
      group.add_members_by_id(user.id)
      expect(group.members.include?(user)).to eq true
      expect(user.groups).to include("Pirate Studies")
      # Check to see if user has role that was assigned to group
      # TODO(bess) Next up: get the ability from the group membership
      # expect(user_ability.collection_editor?).to eq true
    end

    scenario 'admin assigns a collection editor role to a user' do
      group.add_members_by_id(user.id)
      role.resource_type = 'Site'
      role.save
      login_as admin
      visit '/admin/groups'
      expect(page).to have_content 'Manage Groups'
      expect(page).to have_content 'Pirate Studies'
      expect(find('tr#pirate-studies').find('td:first-child').text).to have_content('Pirate Studies')
      find('#edit-pirate-studies-group').click
      expect(page).to have_content 'Edit Group: Pirate Studies'
      click_link('Users')
      expect(page).to have_content 'Current Group Member'
      expect(page).to have_content user.display_name
      click_link('Roles')
      expect(page).to have_content 'Current Group Roles'
      expect(page).to have_content 'No data available in table'
      expect(page).to have_content 'Add Roles to Group'
      find("#add-role-#{role.id}-to-group").click
      expect(find("#assigned-role-#{role.id}").find('td:first-child').text).to eq "Collection Editor"
      # TODO(leaann) Next step is to login as Jane Quest and create or edit a Collection
    end
  end
end
