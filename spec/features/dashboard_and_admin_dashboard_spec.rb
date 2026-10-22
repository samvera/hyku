# frozen_string_literal: true

require 'rails_helper'

# The sidebar's collapsed sub-menus are present in the DOM (only hidden by CSS), and the
# dashboard statistics headings are server-rendered, so this runs under rack_test rather
# than a JS browser.
RSpec.describe 'Dashboard and Admin Dashboard', type: :feature, clean: true, flexible: :either do
  let(:admin_user) { create(:admin) }
  let(:user) { create(:user) }

  before do
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
  end

  it 'shows user dashboard with activity, notifications, proxies, and transfers' do
    login_as user
    visit '/dashboard'
    expect(page).to have_content('User Activity')
    expect(page).to have_content('User Notifications')
    expect(page).to have_content('Current Proxies')
    expect(page).to have_content('Transfers of Ownership')
    expect(page).to have_content('Transfers Sent')
    expect(page).to have_content('Transfers Received')
  end

  # Seeds one record of each kind the user dashboard (hyrax/dashboard/show_user) summarizes.
  it "shows the user's own recent activity, notifications, proxies and transfers" do
    proxy = create(:user, display_name: 'Dashboard Proxy Person')
    other_user = create(:user)
    user.log_event(Hyrax::Event.create('Dashboard distinctive event', Time.current.to_i))
    other_user.log_event(Hyrax::Event.create('Someone else event', Time.current.to_i))
    other_user.send_message(user, 'Dashboard notification body', 'Dashboard notification subject')
    user.can_receive_deposits_from << proxy
    work = create(:generic_work, user:, title: ['Dashboard transfer work'])
    ProxyDepositRequest.create!(work_id: work.id, sending_user: user, receiving_user: other_user,
                                sender_comment: 'Dashboard transfer comment')

    login_as user
    visit '/dashboard'

    within('.user-activity') do
      expect(page).to have_content('Dashboard distinctive event')
      expect(page).not_to have_content('Someone else event')
    end
    within('#notifications') { expect(page).to have_content('Dashboard notification body') }
    within('#proxy_management') { expect(page).to have_css('td.depositor-name', text: 'Dashboard Proxy Person') }
    within('.transfers') do
      expect(page).to have_css('#outgoing-transfers', text: 'Dashboard transfer work')
      expect(page).to have_content(other_user.email)
    end
  end

  it 'shows admin dashboard with statistics and navigation' do
    admin_set = Hyrax::AdminSetCreateService.call!(admin_set: AdminSetResource.new(title: ['Dashboard Activity Set']),
                                                   creating_user: admin_user)
    2.times do |i|
      FactoryBot.valkyrie_create(:generic_work_resource, :public, :with_admin_set,
                                 admin_set:, title: ["Dashboard set work #{i}"], depositor: admin_user.user_key)
    end
    login_as admin_user
    visit '/dashboard'

    # Repository statistics (hyrax/dashboard/show_admin: repository_growth, work_type_graph,
    # resource_type_graph), rendered regardless of analytics settings.
    expect(page).to have_content('Repository Growth')
    expect(page).to have_content('Work Types')
    expect(page).to have_content('Resource Types')
    # Repository Objects: Hyrax 5's hyrax/dashboard/_visibility_graph renders this graph under a
    # "Visibility" header (the hyrax.dashboard.show_admin.repository_objects "Repository Objects"
    # title is no longer used), backed by an sr-only table of published/unpublished counts.
    expect(page).to have_css('#dashboard-repository-objects')
    published_row = find('#dashboard-repository-objects ~ table tbody tr', text: 'Published')
    expect(published_row.all('td').map(&:text)).to eq(%w[Published 2])

    # Recent activity on Administrative Sets (hyrax/dashboard/_tabs + _admin_sets).
    expect(page).to have_link('Admin Sets')
    within('#admin_sets') do
      expect(page).to have_content('Administrative Sets')
      expect(page).to have_content('Recent activity')
      row = find('tbody tr', text: 'Dashboard Activity Set')
      expect(row.all('td').map(&:text)).to eq(['Dashboard Activity Set', '2', '0'])
    end

    within '.sidebar' do
      expect(page).to have_link('Repository Activity')
      expect(page).to have_link('System Status')
      # Tasks
      expect(page).to have_link('Review Submissions')
      expect(page).to have_link('Manage Users')
      expect(page).to have_link('Manage Groups')
      expect(page).to have_link('Manage Embargoes')
      expect(page).to have_link('Manage Leases')
      # Configuration
      expect(page).to have_link('Settings')
    end
  end

  it 'shows stats on the number of users and visitors' do
    skip("Rendered by Hyku's hyrax/dashboard/_user_activity override only when " \
         'current_account.analytics is enabled, and it queries a live analytics provider ' \
         '(Hyrax::Analytics.new_visitors/returning_visitors/total_visitors via Google ' \
         'Analytics or Matomo), which is not available to the test suite.')
  end

  it 'shows Workflow Roles under Configuration only when that menu item is enabled' do
    login_as admin_user

    # Off by default.
    visit '/dashboard'
    within('.sidebar') { expect(page).not_to have_link('Workflow Roles') }

    # Gated by a Flipflop feature in hyrax/dashboard/sidebar/_configuration.
    allow(Flipflop).to receive(:show_workflow_roles_menu_item_in_admin_dashboard_sidebar?).and_return(true)
    visit '/dashboard'
    within('.sidebar') { expect(page).to have_link('Workflow Roles') }
  end

  it 'shows the user sidebar Activity and Repository Contents navigation links' do
    login_as user
    visit '/dashboard'
    within '.sidebar' do
      # Activity > Repository Activity > Activity Summary (admin-only items absent)
      expect(page).to have_link('Activity Summary')
      expect(page).not_to have_link('System Status')
      expect(page).not_to have_link('Reports')

      # Activity > Your activity (a collapsed sub-menu; its links are in the DOM)
      expect(page).to have_link('Your activity')
      expect(page).to have_link('Profile')
      expect(page).to have_link('Notifications')
      expect(page).to have_link('Transfers')
      expect(page).to have_link('Manage Proxies')

      # Repository Contents
      expect(page).to have_link('Collections', exact_text: true)
      expect(page).to have_link('Works', exact_text: true)

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

      # Configuration > Settings (a collapsed sub-menu; its links are in the DOM)
      expect(page).to have_link('Settings')
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

  # Bulkrax adds these via hyrax/dashboard/sidebar/_bulkrax_sidebar_additions, gated on
  # Ability#can_import_works? / #can_export_works? (Hyku: can_create_any_work?), which
  # needs an admin set the user can deposit into.
  it 'shows Bulkrax Importers and Exporters links under Repository Contents' do
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    login_as admin_user
    visit '/dashboard'
    within '.sidebar' do
      expect(page).to have_link('Importers', href: %r{/importers})
      expect(page).to have_link('Exporters', href: %r{/exporters})
    end
  end

  context 'with a default admin set to deposit into' do
    before { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

    it 'shows Importers and Exporters to a regular user with deposit rights' do
      depositor = create(:user, roles: [:work_depositor])
      login_as depositor
      visit '/dashboard'
      within '.sidebar' do
        expect(page).to have_link('Importers', href: %r{/importers})
        expect(page).to have_link('Exporters', href: %r{/exporters})
      end
    end

    # Hyku's AdminSetCreateServiceDecorator#create_default_access_for grants registered users no
    # deposit access to the default admin set, so a plain user cannot create works.
    it 'hides Importers and Exporters from a user who cannot create works' do
      login_as user
      visit '/dashboard'
      within '.sidebar' do
        expect(page).to have_link('Works', exact_text: true) # the Repository Contents section rendered
        expect(page).not_to have_link('Importers')
        expect(page).not_to have_link('Exporters')
      end
    end
  end
end
