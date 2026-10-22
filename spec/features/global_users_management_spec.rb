# frozen_string_literal: true

require 'rails_helper'

# Global (admin host) user management: app/controllers/proprietor/users_controller.rb and
# app/views/proprietor/users. Users live in the shared (public) schema, so this list spans tenants.
RSpec.describe 'Global users management', type: :feature, multitenant: true, clean: true, flexible: :either do
  let(:superadmin) { create(:superadmin, email: 'global.boss@example.com') }
  let!(:target) do
    create(:user, email: 'pat.target@example.com', display_name: 'Pat Target',
                  department: 'Zoology Dept', title: 'Curator of Owls', affiliation: 'Night Society')
  end

  around do |example|
    default_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = default_host
  end

  before { login_as superadmin, scope: :user }

  def row_for(email)
    find('table.datatable tbody tr', text: email)
  end

  # Manual Test Plan: "Global Users Index Page (Admin only)"
  describe 'index page' do
    it 'lists every user with their attributes in separate columns' do
      visit '/proprietor/users'

      headers = all('table.datatable thead th').map(&:text)
      expect(headers).to eq(%w[Email Display\ name Department Title Affiliation SuperAdmin Actions])

      target_cells = row_for('pat.target@example.com').all('td').map(&:text)
      expect(target_cells[0..5])
        .to eq(['pat.target@example.com', 'Pat Target', 'Zoology Dept', 'Curator of Owls', 'Night Society', 'false'])
      # The signed-in superadmin is listed too, with the Superadmin column flipped.
      expect(row_for('global.boss@example.com').all('td')[5].text).to eq('true')
    end

    it 'goes to the Manage User page from Manage' do
      visit '/proprietor/users'
      within(row_for('pat.target@example.com')) { click_link 'Manage' }

      expect(page).to have_current_path(proprietor_user_path(target), ignore_query: true)
      expect(page).to have_css('h1', text: 'Manage User')
      expect(page).to have_css('h2', text: 'Pat Target (pat.target@example.com)')
    end

    it 'goes to the Edit User form from Edit' do
      visit '/proprietor/users'
      within(row_for('pat.target@example.com')) { click_link 'Edit' }

      expect(page).to have_current_path(edit_proprietor_user_path(target), ignore_query: true)
      expect(page).to have_field('Email address', with: 'pat.target@example.com')
    end

    it 'goes to the Create a new user form from Create New' do
      visit '/proprietor/users'
      click_link 'Create New'

      expect(page).to have_current_path(new_proprietor_user_path, ignore_query: true)
      expect(page).to have_css('h1', text: 'Create a new user')
    end

    it 'offers Become to sign in as another user' do
      skip('Not implemented in base Hyku: app/views/proprietor/users/index.html.erb has no Become link, ' \
           'although Proprietor::UsersController#become and its POST route exist.')
    end

    context 'with javascript', js: true do
      # Potential duplicate: spec/controllers/proprietor/users_controller_spec.rb:154 (DELETE #destroy removes the user)
      it 'deletes a user after confirming' do
        visit '/proprietor/users'
        expect(page).to have_css('table.datatable tbody tr', text: 'pat.target@example.com')

        accept_confirm('Are you sure you wish to delete this user?') do
          within(row_for('pat.target@example.com')) { click_link 'Delete' }
        end

        expect(page).to have_content('User was successfully destroyed.')
        expect(page).not_to have_css('table.datatable tbody tr', text: 'pat.target@example.com')
        expect(page).to have_css('table.datatable tbody tr', text: 'global.boss@example.com')
        expect(User.find_by(email: 'pat.target@example.com')).to be_nil
      end

      it 'filters the users table with the search box' do
        create(:user, email: 'quinn.other@example.com', display_name: 'Quinn Other')
        visit '/proprietor/users'
        expect(page).to have_css('table.datatable tbody tr', text: 'quinn.other@example.com')

        find('.dataTables_filter input').fill_in(with: 'Zoology')

        expect(page).to have_css('table.datatable tbody tr', count: 1)
        expect(page).to have_css('table.datatable tbody tr', text: 'pat.target@example.com')
        expect(page).not_to have_css('table.datatable tbody tr', text: 'quinn.other@example.com')
        expect(page).not_to have_css('table.datatable tbody tr', text: 'global.boss@example.com')
      end
    end
  end

  # Manual Test Plan: "Global Users New Page (Admin only)"
  describe 'new page' do
    it 'creates a user on Save and returns to the users list' do
      visit new_proprietor_user_path
      fill_in 'Display Name', with: 'Robin Fresh'
      fill_in 'Email address', with: 'robin.fresh@example.com'
      fill_in 'Password', with: 'Sup3rS3cret!'
      fill_in 'Department', with: 'Botany Dept'
      click_button 'Save'

      expect(page).to have_current_path(proprietor_users_path, ignore_query: true)
      expect(page).to have_content('User was successfully created.')
      expect(row_for('robin.fresh@example.com')).to have_content('Robin Fresh')
      created = User.find_by(email: 'robin.fresh@example.com')
      expect(created).to have_attributes(display_name: 'Robin Fresh', department: 'Botany Dept')
      expect(created.valid_password?('Sup3rS3cret!')).to be true
    end

    it 're-renders the form with errors when an attribute is invalid' do
      visit new_proprietor_user_path
      fill_in 'Display Name', with: 'Broken Email'
      fill_in 'Email address', with: 'not-an-email'
      fill_in 'Password', with: 'Sup3rS3cret!'

      expect { click_button 'Save' }.not_to change(User, :count)
      expect(page).to have_css('#error_explanation', text: /prohibited this user from being saved/)
      expect(page).to have_css('#error_explanation li', text: 'email is invalid')
      expect(page).to have_css('h1', text: 'Create a new user')
      expect(page).to have_field('Display Name', with: 'Broken Email')
    end

    it 'returns to the users list on Cancel' do
      visit new_proprietor_user_path
      click_link 'Cancel'

      expect(page).to have_current_path(proprietor_users_path, ignore_query: true)
      expect(page).to have_css('h1', text: 'Manage Users')
    end
  end

  # Manual Test Plan: "Global Users Manage Page (Admin only)"
  describe 'manage page' do
    it 'assigns the superadmin role with the checkbox and Update' do
      expect(target.superadmin?).to be false
      visit proprietor_user_path(target)
      check 'superadmin'
      click_button 'Update'

      expect(page).to have_current_path(proprietor_users_path, ignore_query: true)
      expect(page).to have_content('User was successfully updated.')
      expect(row_for('pat.target@example.com').all('td')[5].text).to eq('true')
      expect(User.find(target.id).superadmin?).to be true
      # Superadmin privileges: the promoted user can reach this admin-only page.
      login_as User.find(target.id), scope: :user
      visit proprietor_users_path
      expect(page).to have_css('h1', text: 'Manage Users')
    end

    it 'unassigns the superadmin role by clearing the checkbox' do
      target.add_role(:superadmin)
      visit proprietor_user_path(target)
      expect(page).to have_checked_field('superadmin')
      uncheck 'superadmin'
      click_button 'Update'

      expect(page).to have_current_path(proprietor_users_path, ignore_query: true)
      expect(User.find(target.id).superadmin?).to be false
    end

    it 'returns to the users list on Cancel' do
      visit proprietor_user_path(target)
      click_link 'Cancel'

      expect(page).to have_current_path(proprietor_users_path, ignore_query: true)
    end

    it 'goes to the Edit User form from Edit' do
      visit proprietor_user_path(target)
      click_link 'Edit'

      expect(page).to have_current_path(edit_proprietor_user_path(target), ignore_query: true)
      expect(page).to have_css('h1', text: 'Edit User')
    end
  end

  # Manual Test Plan: "Global Users Edit Page (Admin only)"
  describe 'edit page' do
    it "pre-fills the user's Display Name and Email address" do
      visit edit_proprietor_user_path(target)

      expect(page).to have_field('Display Name', with: 'Pat Target')
      expect(page).to have_field('Email address', with: 'pat.target@example.com')
      expect(page).to have_field('Department', with: 'Zoology Dept')
    end

    # Potential duplicate: spec/controllers/proprietor/users_controller_spec.rb:94 (PUT #update saves attributes)
    it 'saves changes and returns to the users list' do
      visit edit_proprietor_user_path(target)
      fill_in 'Display Name', with: 'Patricia Renamed'
      fill_in 'Title', with: 'Head of Owls'
      click_button 'Save changes'

      expect(page).to have_current_path(proprietor_users_path, ignore_query: true)
      expect(page).to have_content('User was successfully updated.')
      cells = row_for('pat.target@example.com').all('td').map(&:text)
      expect(cells[1]).to eq('Patricia Renamed')
      expect(cells[3]).to eq('Head of Owls')
      expect(target.reload).to have_attributes(display_name: 'Patricia Renamed', title: 'Head of Owls')
    end

    it 'returns to the users list on Cancel without saving' do
      visit edit_proprietor_user_path(target)
      fill_in 'Display Name', with: 'Unsaved Name'
      click_link 'Cancel'

      expect(page).to have_current_path(proprietor_users_path, ignore_query: true)
      expect(target.reload.display_name).to eq('Pat Target')
    end
  end
end
