# frozen_string_literal: true

require 'rails_helper'
RSpec.describe 'Manage Group Roles', type: :feature, js: true, clean: true do
  include Warden::Test::Helpers

  context 'as an admin user on the manage group roles view' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:group) { FactoryBot.create(:group) }

    before do
      login_as admin
    end

    it 'can add a role to the group' do
      visit "/admin/groups/#{group.id}/roles"
      expect(page).to have_content('Current Group Roles')
      expect(page).to have_content('Add Roles to Group')
      expect(page).to have_selector(:link_or_button, 'Add')

      expect(find('.add-group-roles')).to have_content('Admin')
      expect(find('.current-group-roles')).to have_content('No data available in table')

      find('input.btn-success').click

      expect(page).to have_content('Role has successfully been added to Group')
      expect(find('.add-group-roles')).to have_content('No data available in table')
      expect(find('.current-group-roles')).to have_content('Admin')
    end

    it 'can remove a role from the group' do
      group.roles << Role.find_by(name: 'admin')

      visit "/admin/groups/#{group.id}/roles"
      expect(page).to have_content('Current Group Roles')
      expect(page).to have_content('Add Roles to Group')
      expect(page).to have_selector(:link_or_button, 'Remove')

      expect(find('.current-group-roles')).to have_content('Admin')
      expect(find('.add-group-roles')).to have_content('No data available in table')

      find('input.btn-danger').click

      expect(page).to have_content('Role has successfully been removed from Group')
      expect(find('.current-group-roles')).to have_content('No data available in table')
      expect(find('.add-group-roles')).to have_content('Admin')
    end
  end
end
