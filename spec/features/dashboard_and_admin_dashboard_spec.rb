# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard and Admin Dashboard', type: :feature, js: true, clean: true do
  let(:admin_user) { create(:admin) }
  let(:user) { create(:user) }

  it 'shows user dashboard with activity, notifications, proxies, and transfers' do
    login_as user
    visit '/dashboard'
    expect(page).to have_content('Recent Activity')
    expect(page).to have_content('Notifications')
    expect(page).to have_content('Proxies')
    expect(page).to have_content('Transfers')
    expect(page).to have_content('Collections')
    expect(page).to have_content('Works')
  end

  it 'shows admin dashboard with statistics and navigation' do
    login_as admin_user
    visit '/dashboard'
    expect(page).to have_content('Site Statistics')
    expect(page).to have_content('Repository Activity')
    expect(page).to have_content('System Status')
    expect(page).to have_content('Review Submissions')
    expect(page).to have_content('Manage Users')
    expect(page).to have_content('Manage Groups')
    expect(page).to have_content('Manage Embargoes')
    expect(page).to have_content('Manage Leases')
    expect(page).to have_content('Settings')
    expect(page).to have_content('Workflow Roles')
  end

  it 'shows the user sidebar Activity and Repository Contents navigation links' do
    login_as user
    visit '/dashboard'
    within '.sidebar' do
      # Activity > Repository Activity > Activity Summary (admin-only items absent)
      expect(page).to have_link('Activity Summary')
      expect(page).not_to have_link('System Status')
      expect(page).not_to have_link('Reports')

      # Activity > Your activity (collapsed menu; open it before asserting sub-links)
      expect(page).to have_link('Your activity')
      click_link 'Your activity'
      expect(page).to have_link('Profile')
      expect(page).to have_link('Notifications')
      expect(page).to have_link('Transfers')
      expect(page).to have_link('Manage Proxies')

      # Repository Contents
      expect(page).to have_link('Collections')
      expect(page).to have_link('Works')

      # A regular user has no Configuration/Settings section
      expect(page).not_to have_link('Settings')
    end
  end

  it 'shows the admin Repository Activity and Configuration > Settings submenu links' do
    login_as admin_user
    visit '/dashboard'
    within '.sidebar' do
      # Activity > Repository Activity (admin also sees System Status and Reports)
      expect(page).to have_link('Activity Summary')
      expect(page).to have_link('System Status')
      expect(page).to have_link('Reports')

      # Configuration > Settings (collapsed menu; open it before asserting sub-links)
      expect(page).to have_link('Settings')
      click_link 'Settings'
      expect(page).to have_link('Accounts')
      expect(page).to have_link('Labels')
      expect(page).to have_link('Appearance')
      expect(page).to have_link('Collection Types')
      expect(page).to have_link('Pages')
      expect(page).to have_link('Content Blocks')
      expect(page).to have_link('Features')
      expect(page).to have_link('Available Work Types')
    end
  end

  it 'shows Bulkrax Importers and Exporters links under Repository Contents' do
    # These links come from the Bulkrax `hyrax/dashboard/sidebar/_repository_content` override and are
    # gated on Ability#can_import_works?/#can_export_works? (i.e. can_create_any_work?). The exact
    # Bulkrax 9.5.1 partial and its view-path precedence over the Hyrax partial cannot be pinned down
    # from the offline gem checkouts available here, so this is left as a real-run verification rather
    # than a guessed assertion.
    skip('Importers/Exporters rendering not verifiable from offline gem sources; confirm in a real run')
    login_as admin_user
    visit '/dashboard'
    within '.sidebar' do
      expect(page).to have_link('Importers')
      expect(page).to have_link('Exporters')
    end
  end
end

# ## Dashboard Page
# [Back to TOC](#table-of-contents)

# ![image35](https://github.com/samvera/hyku/assets/19597776/f8eca63f-290c-480f-bdf5-26b482a57a02)

# ### As a user:

# - [ ] I can see recent activity from my account
# - [ ] I can see any notifications associated with my account
# - [ ] I can see any current proxies I have
# - [ ] I can see both sent and received transfer of ownership requests
# - [ ] In the sidebar, I can see options/dropdown menus for
#   - [ ] Activity
#     - [ ] Repository Activity
#       - [ ] Activity Summary
#     - [ ] Your Activity
#       - [ ] Profile
#       - [ ] Notifications
#       - [ ] Transfers
#       - [ ] Manage Proxies
#   - [ ] Repository Contents
#     - [ ] Collections
#     - [ ] Works
#     - [ ] Importers
#     - [ ] Exporters

# ## Dashboard Page (Admin)
# [Back to TOC](#table-of-contents)

# ![image75](https://github.com/samvera/hyku/assets/19597776/6b9dc5ca-f249-48d9-9bb3-4895c7917201)

# ### As an admin:

# - [ ] I can see various site statistics, including:
#   - [ ] Stats on number of users & visitors
#   - [ ] Recent activity on Administrative Sets
#   - [ ] User activity, Repository Growth, Repository Objects
# - [ ] In the sidebar, I can see options/dropdowns for
#   - [ ] Activity
#     - [ ] Repository Activity
#       - [ ] Activity Summary
#       - [ ] System Status
#     - [ ] Your activity
#       - [ ] Profile
#       - [ ] Notifications
#       - [ ] Transfers
#       - [ ] Manage Proxies
#     - [ ] Reports
#   - [ ] Repository Contents
#     - [ ] Collections
#     - [ ] Works
#     - [ ] Importers
#     - [ ] Exporters
#   - [ ] Tasks
#     - [ ] Review Submissions
#     - [ ] Manage Users
#     - [ ] Manage Groups
#     - [ ] Manage Embargoes
#     - [ ] Manage Leases
#   - [ ] Configuration
#     - [ ] Settings
#       - [ ] Account
#       - [ ] Labels
#       - [ ] Appearance
#       - [ ] Collection Types
#       - [ ] Pages
#       - [ ] Content Blocks
#       - [ ] Features
#       - [ ] Available Work Types
#     - [ ] Workflow Roles