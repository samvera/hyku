# frozen_string_literal: true

require 'rails_helper'

# Manual Test Plan: "Manage Users Page", "Manage Groups Index Page", "Manage Groups New Page",
# and "Manage Groups Edit Page" (Description, Users, and Remove tabs).
RSpec.describe 'Manage Users and Groups', type: :feature, clean: true do
  let(:admin) { create(:admin, email: 'admin-manager@example.com') }

  before do
    # Seed the default groups with their humanized names (user creation would otherwise create a
    # nameless "registered" group).
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    login_as admin
  end

  # Manual Test Plan: "Manage Users Page"
  describe 'Manage Users Page' do
    let!(:depositor) do
      create(:user, email: 'dora.depositor@example.com', roles: [:work_depositor],
                    last_sign_in_at: Time.zone.local(2024, 3, 5, 10, 15))
    end
    let!(:reader) { create(:user, email: 'rex.reader@example.com', roles: [:collection_reader]) }

    it 'shows the exact total number of users in the repository' do
      admin # the admin plus the two let! users
      visit '/admin/users'

      expect(find('.users-listing .card-header')).to have_text(/\AThere are 3 users in this repository\.\z/)
    end

    # Potential duplicate: spec/views/hyrax/admin/users/index.html.erb_spec.rb:37 (user list columns, status, delete buttons)
    it 'lists each user with their username, roles, last access, and status' do
      visit '/admin/users'

      within("tr##{depositor.email.parameterize}") do
        expect(page).to have_link('dora.depositor@example.com')
        expect(find('td.site-roles')).to have_text('Work Depositor')
        expect(find('td.site-roles')).not_to have_text('Collection Reader')
        # Last access is the last sign-in time (long ordinal format).
        expect(page).to have_css('relative-time', text: 'March 5th, 2024 10:15')
        expect(page).to have_css('td', exact_text: 'Active')
      end

      within("tr##{reader.email.parameterize}") do
        expect(page).to have_link('rex.reader@example.com')
        expect(find('td.site-roles')).to have_text('Collection Reader')
        # A user who never signed in shows their creation time as last access.
        expect(page).to have_css('relative-time', text: reader.created_at.to_formatted_s(:long_ordinal))
      end
    end

    # Potential duplicate: spec/features/manage_user_groups_and_roles_spec.rb:47 (invites a user via the email form)
    it 'adds/invites a user via email with a role, listed as Pending' do
      visit '/admin/users'

      within('.users-invite') do
        fill_in 'Email address', with: 'ivy.invitee@example.com'
        select 'Work Depositor', from: 'user_role'
        click_button 'Invite user'
      end

      expect(page).to have_content('An invitation email has been sent to ivy.invitee@example.com.')
      invitee = User.find_by(email: 'ivy.invitee@example.com')
      expect(invitee).to be_invited_to_sign_up
      expect(invitee.site_roles.map(&:name)).to include('work_depositor')

      within('tr#ivy-invitee-example-com') do
        expect(page).to have_css('td', exact_text: 'Pending')
        expect(find('td.site-roles')).to have_text('Work Depositor')
      end
      expect(find('.users-listing .card-header')).to have_text('There are 4 users in this repository.')
    end

    it 'removes a user from the repository with the Delete button next to them' do
      visit '/admin/users'

      within("tr##{reader.email.parameterize}") { click_link 'Delete' }

      expect(page).to have_content('User "rex.reader@example.com" has been successfully deleted.')
      expect(page).not_to have_css("tr##{reader.email.parameterize}")
      expect(page).to have_css("tr##{depositor.email.parameterize}")
      # Deleting removes the user's roles in this tenant (the account itself remains).
      expect(reader.reload.roles).to be_empty
    end
  end

  # Manual Test Plan: "Manage Groups Index Page"
  describe 'Manage Groups Index Page' do
    let(:member_one) { create(:user, email: 'alpha.one@example.com') }
    let(:member_two) { create(:user, email: 'alpha.two@example.com') }
    let!(:alpha) do
      FactoryBot.create(:group, name: 'alpha_testers', humanized_name: 'Alpha Testers',
                                description: 'Early access testers', member_users: [member_one, member_two],
                                created_at: Time.zone.local(2025, 3, 14, 12))
    end
    let!(:beta) do
      FactoryBot.create(:group, name: 'beta_reviewers', humanized_name: 'Beta Reviewers', description: 'Reviewers')
    end

    # Potential duplicate: spec/views/admin/groups/index.html.erb_spec.rb:22 (total number of groups)
    it 'shows the total number of groups' do
      visit '/admin/groups'

      expect(find('.group-listing .card-header')).to have_text("There are #{Hyrax::Group.count} groups in this repository.")
    end

    # Potential duplicate: spec/views/admin/groups/index.html.erb_spec.rb:27 (group name, user count, created date)
    it 'lists each group with its name, user count, and creation date' do
      visit '/admin/groups'

      within('tr#alpha_testers') do
        expect(page).to have_css('b', exact_text: 'Alpha Testers')
        expect(page).to have_text('Early access testers')
        expect(find('td:nth-child(3)')).to have_text(/\A2\z/)
        expect(find('td:nth-child(4)')).to have_text('03/14/2025')
      end
      within('tr#beta_reviewers') do
        expect(page).to have_css('b', exact_text: 'Beta Reviewers')
        expect(find('td:nth-child(3)')).to have_text(/\A0\z/)
      end
    end

    it 'searches for specific groups' do
      visit '/admin/groups'

      fill_in 'group_search_q', with: 'Alpha'
      click_button 'Go'

      expect(page).to have_css('tr#alpha_testers')
      expect(page).not_to have_css('tr#beta_reviewers')
    end

    it 'opens the new group form with Create New Group' do
      visit '/admin/groups'
      click_link 'Create New Group'

      expect(page).to have_current_path(%r{\A/admin/groups/new})
      expect(page).to have_css('h1', text: 'New Group')
    end

    it 'opens a group for editing with Edit group & users' do
      visit '/admin/groups'
      within('tr#alpha_testers') { click_link 'Edit group & users' }

      expect(page).to have_current_path(%r{\A/admin/groups/#{alpha.id}/edit})
      expect(page).to have_css('h1', text: 'Edit Group: Alpha Testers')
    end
  end

  # Manual Test Plan: "Manage Groups New Page"
  describe 'Manage Groups New Page' do
    it 'returns to the Manage Groups index from the back link' do
      visit '/admin/groups/new'
      find('a.nav-escape-link', text: 'return to Manage Groups').click

      expect(page).to have_current_path(%r{\A/admin/groups(\?|\z)})
      expect(page).to have_css('h1', text: 'Manage Groups')
    end

    # Potential duplicate: spec/views/admin/groups/new.html.erb_spec.rb:17 (disabled Users/Remove tabs, name/description inputs)
    it 'has a required Name and a Description, with the other tabs disabled' do
      visit '/admin/groups/new'

      expect(page).to have_field('Name', type: 'text')
      expect(find_field('group_humanized_name')[:required]).to eq('required')
      expect(page).to have_css('label[for=group_humanized_name] .required-tag', text: 'required')
      expect(page).to have_field('Description', type: 'textarea')
      expect(find_field('group_description')[:required]).to be_nil

      within('.panel-tab-wrapper') do
        expect(page).to have_css('a.nav-link.active', text: 'Description')
        expect(page).to have_css('a.nav-link.disabled[href="javascript:void(0);"]', text: 'Users')
        expect(page).to have_css('a.nav-link.disabled[href="javascript:void(0);"]', text: 'Remove')
      end
    end

    it 'creates a new group with Save' do
      visit '/admin/groups/new'
      fill_in 'Name', with: 'Gamma Curators'
      fill_in 'Description', with: 'Curates the gamma collection'

      expect { click_button 'Save' }.to change(Hyrax::Group, :count).by(1)

      group = Hyrax::Group.find_by(humanized_name: 'Gamma Curators')
      expect(group.description).to eq('Curates the gamma collection')
      expect(page).to have_css('b', exact_text: 'Gamma Curators')
    end

    it 'cancels the new group and returns to the Manage Groups index' do
      visit '/admin/groups/new'
      fill_in 'Name', with: 'Never Saved Group'

      expect { click_link 'Cancel' }.not_to change(Hyrax::Group, :count)
      expect(page).to have_current_path(%r{\A/admin/groups(\?|\z)})
      expect(page).not_to have_content('Never Saved Group')
    end
  end

  # Manual Test Plan: "Manage Groups Edit Page"
  describe 'Manage Groups Edit Page' do
    let!(:group) do
      FactoryBot.create(:group, name: 'delta_editors', humanized_name: 'Delta Editors',
                                description: 'Edits delta records', member_users: [member])
    end
    let(:member) do
      create(:user, email: 'zelda.member@example.com', display_name: 'Zelda Member',
                    created_at: Time.zone.local(2024, 2, 3, 9), updated_at: Time.zone.local(2024, 6, 7, 9))
    end

    it 'returns to the Manage Groups index from the back link on the Description, Users, and Remove tabs' do
      %w[edit users remove].each do |tab|
        visit "/admin/groups/#{group.id}/#{tab}"
        find('a.nav-escape-link', text: 'return to Manage Groups').click

        expect(page).to have_current_path(%r{\A/admin/groups(\?|\z)})
        expect(page).to have_css('tr#delta_editors')
      end
    end

    context 'Description tab' do
      it 'shows the filled-in form and saves changes' do
        visit "/admin/groups/#{group.id}/edit"

        expect(page).to have_field('Name', with: 'Delta Editors')
        expect(find_field('group_humanized_name')[:required]).to eq('required')
        expect(page).to have_field('Description', with: 'Edits delta records')

        fill_in 'Name', with: 'Delta Editors Renamed'
        fill_in 'Description', with: 'Now edits epsilon records'
        click_button 'Save changes'

        group.reload
        expect(group.humanized_name).to eq('Delta Editors Renamed')
        expect(group.description).to eq('Now edits epsilon records')
      end

      it 'cancels the edits and returns to the Manage Groups index' do
        visit "/admin/groups/#{group.id}/edit"
        fill_in 'Name', with: 'Discarded Name'
        click_link 'Cancel'

        expect(page).to have_current_path(%r{\A/admin/groups(\?|\z)})
        expect(group.reload.humanized_name).to eq('Delta Editors')
        within('tr#delta_editors') { expect(page).to have_css('b', exact_text: 'Delta Editors') }
      end
    end

    context 'Users tab' do
      # Potential duplicate: spec/views/admin/groups/users.html.erb_spec.rb:68 (lists group members)
      it 'lists current members with their name, username, joined date, and last access' do
        visit "/admin/groups/#{group.id}/users"

        within('.group-user-listing table') do
          expect(page).to have_css('th', text: 'Name')
          expect(page).to have_css('th', text: 'Username')
          expect(page).to have_css('th', text: 'Joined')
          expect(page).to have_css('th', text: 'Last access')

          row = find('tbody tr', text: 'zelda.member@example.com')
          expect(row.find('td:nth-child(1)')).to have_text(/\AZelda Member\z/)
          expect(row.find('td:nth-child(2)')).to have_text(/\Azelda.member@example.com\z/)
          expect(row.find('td:nth-child(3)')).to have_text(/\A02\/03\/2024\z/)
          expect(row.find('td:nth-child(4)')).to have_text(/\A06\/07\/2024\z/)
        end
      end

      it 'removes a member from the group with the Remove button next to them' do
        visit "/admin/groups/#{group.id}/users"

        within('.group-user-listing tbody tr', text: 'zelda.member@example.com') { click_button 'Remove' }

        expect(group.reload.members).not_to include(member)
        expect(page).not_to have_css('.group-user-listing tbody tr', text: 'zelda.member@example.com')
      end

      it 'searches through the users within the group' do
        group.add_members_by_id(create(:user, email: 'yuri.other@example.com', display_name: 'Yuri Other').id)
        visit "/admin/groups/#{group.id}/users"
        expect(page).to have_css('.group-user-listing tbody tr', text: 'yuri.other@example.com')

        within('form.list-scope') do
          fill_in 'group_search_q', with: 'zelda'
          click_button 'Go'
        end

        expect(page).to have_css('.group-user-listing tbody tr', text: 'zelda.member@example.com')
        expect(page).not_to have_css('.group-user-listing tbody tr', text: 'yuri.other@example.com')
      end

      it 'searches for an existing user and adds them to the group', js: true do
        newcomer = create(:user, email: 'xena.newcomer@example.com', display_name: 'Xena Newcomer')
        visit "/admin/groups/#{group.id}/users"

        fill_in 'user_search_uq', with: 'xena'
        find('.js-typeahead__suggestion', text: 'xena.newcomer@example.com').click

        expect(page).to have_css('.group-user-listing tbody tr', text: 'xena.newcomer@example.com')
        expect(group.reload.members).to include(newcomer)
      end
    end

    context 'Remove tab' do
      # Potential duplicate: spec/features/user_roles_spec.rb:82 (Remove Group warning text)
      it 'warns about the irreversible removal and deletes the group' do
        visit "/admin/groups/#{group.id}/remove"

        within('.callout-danger') do
          expect(page).to have_css('h3', text: 'Remove Group “Delta Editors”')
          expect(page).to have_text('This action is irreversible. It will remove all privileges group members ' \
                                    'have been assigned through this group.')
        end

        # Potential duplicate: spec/features/groups_spec.rb:25 (removes a non-default group via Remove)
        # Potential duplicate: spec/features/group_spec.rb:24 (removes a non-default group via Remove)
        expect { within('.callout-action') { click_link 'Remove' } }.to change(Hyrax::Group, :count).by(-1)
        expect(Hyrax::Group.exists?(name: 'delta_editors')).to be false
        expect(page).to have_current_path(%r{\A/admin/groups(\?|\z)})
        expect(page).not_to have_css('tr#delta_editors')
      end
    end
  end
end
