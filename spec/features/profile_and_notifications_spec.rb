# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile and Notifications', type: :feature, clean: true, flexible: :either do
  let(:user) { create(:user, email: 'profileuser@example.com') }
  # Profiles are addressed by the user's to_param (email with '.' => '-dot-').
  let(:profile_path) { "/dashboard/profiles/#{user.to_param}" }

  before do
    login_as user
  end

  it 'saves the profile and returns to the profile page' do
    visit "#{profile_path}/edit"
    fill_in 'Twitter Handle', with: 'profileuser'
    fill_in 'Facebook Handle', with: 'profileuser.fb'
    # ORCID's own documentation example iD.
    fill_in 'user_orcid', with: '0000-0002-1825-0097'
    fill_in 'user_googleplus_handle', with: 'profileuser.gplus'
    click_button 'Save Profile'

    expect(page).to have_current_path(profile_path, ignore_query: true)
    expect(page).to have_link('profileuser', href: 'http://twitter.com/profileuser')
    expect(user.reload.twitter_handle).to eq('profileuser')
    expect(user.facebook_handle).to eq('profileuser.fb')
    expect(user.orcid).to include('0000-0002-1825-0097')
    expect(user.googleplus_handle).to eq('profileuser.gplus')
  end

  # Profile SHOW page. Labels are grounded in the Hyrax profile show view
  # (hyrax/dashboard/profiles/show -> hyrax/users/_vitals + _user_info) and the
  # stats locale keys.
  it 'displays join date, stats, email, and edit link on the profile show page' do
    user.update!(created_at: Time.zone.local(2024, 3, 7, 12))
    visit profile_path

    # I can see the date that I joined the site (hyrax.dashboard.stats.joined_on)
    expect(page).to have_content('Joined on Mar 07, 2024')

    # With no recorded usage, every Views/Downloads counter is zero.
    expect(all('.views-downloads-dashboard li').map { |li| li.text.squish })
      .to eq(['0 Metadata Views', '0 Views', '0 Downloads'])

    # I can see the email associated with my account (rendered via mail_to).
    within('#user_info') { expect(page).to have_link(user.email, href: "mailto:#{user.email}") }

    # I can click Edit Profile, directing me to the Edit Profile form.
    click_link 'Edit Profile'
    expect(page).to have_current_path("#{profile_path}/edit", ignore_query: true)
    expect(page).to have_field('Twitter Handle')
  end

  # Views/Downloads sum the user's UserStat rows (Hyrax::UserUsageStats).
  it 'shows the summed number of views and downloads under Works created' do
    UserStat.create!(user_id: user.id, date: 2.days.ago, work_views: 3, file_views: 2, file_downloads: 1)
    UserStat.create!(user_id: user.id, date: 1.day.ago, work_views: 4, file_views: 3, file_downloads: 1)
    visit profile_path

    expect(all('.views-downloads-dashboard li').map { |li| li.text.squish })
      .to eq(['7 Metadata Views', '5 Views', '2 Downloads'])
  end

  describe 'Works created and Collections created' do
    let(:other_user) { create(:user) }

    before do
      %w[Alpha Beta Gamma].each do |name|
        FactoryBot.valkyrie_create(:generic_work_resource, :public, title: ["Profile work #{name}"],
                                                                    depositor: user.user_key)
      end
      FactoryBot.valkyrie_create(:generic_work_resource, :public, title: ['Someone else work'],
                                                                  depositor: other_user.user_key)
      %w[One Two].each do |name|
        FactoryBot.valkyrie_create(:hyku_collection, :public, user:, title: ["Profile collection #{name}"])
      end
      FactoryBot.valkyrie_create(:hyku_collection, :public, user: other_user, title: ['Someone else collection'])
    end

    it 'shows the number of works and collections the user created' do
      visit profile_path

      # The count badge sits in the same list item as its link.
      expect(find('.list-group-item', text: 'Works created').first('.badge')).to have_text('3', exact: true)
      expect(find('.list-group-item', text: 'Collections created').first('.badge')).to have_text('2', exact: true)
    end

    # Remove this comment and the `pending` call to re-enable this test when issue #3415 is fixed.
    # KNOWN APPLICATION ISSUE: the profile link's f[depositor_ssim] filter is ignored because
    # depositor_ssim is not a configured facet. Fix goes in app/controllers/catalog_controller.rb.
    it "links Works created to a search of only the user's works" do
      pending("Catalog ignores the depositor filter, so other users' works are listed")
      visit profile_path
      click_link 'Works created'

      expect(page).to have_current_path(%r{/catalog})
      %w[Alpha Beta Gamma].each { |name| expect(page).to have_link("Profile work #{name}") }
      expect(page).not_to have_link('Someone else work')
      expect(page).not_to have_link('Profile collection One')
    end

    # Remove this comment and the `pending` call to re-enable this test when issue #3415 is fixed.
    # KNOWN APPLICATION ISSUE: the profile link's f[depositor_ssim] filter is ignored because
    # depositor_ssim is not a configured facet. Fix goes in app/controllers/catalog_controller.rb.
    it "links Collections created to a search of only the user's collections" do
      pending("Catalog ignores the depositor filter, so other users' collections are listed")
      visit profile_path
      click_link 'Collections created'

      expect(page).to have_current_path(%r{/catalog})
      expect(page).to have_link('Profile collection One')
      expect(page).to have_link('Profile collection Two')
      expect(page).not_to have_link('Someone else collection')
      expect(page).not_to have_link('Profile work Alpha')
    end
  end

  # Profile EDIT page (Hyku override app/views/hyrax/dashboard/profiles/_edit_primary.html.erb).
  it 'renders the profile picture, delete-picture, ORCID, Twitter, Facebook, and Google+ inputs' do
    visit "#{profile_path}/edit"

    expect(page).to have_css("input#user_avatar[type='file']")
    expect(page).to have_field('Delete picture', type: 'checkbox')
    expect(page).to have_field('ORCID Profile')
    expect(page).to have_field('Twitter Handle')
    expect(page).to have_field('Facebook Handle')
    expect(page).to have_field('Google+ Handle')
    expect(page).to have_button('Save Profile')
  end

  it 'uploads a profile picture and removes it with Delete picture' do
    visit "#{profile_path}/edit"
    attach_file 'user_avatar', Rails.root.join('spec', 'fixtures', 'images', 'world.png')
    click_button 'Save Profile'

    expect(page).to have_current_path(profile_path, ignore_query: true)
    expect(user.reload.avatar?).to be true
    expect(user.avatar.url).to end_with('world.png')
    # The dashboard sidebar shows the avatar thumbnail (hyrax/dashboard/_sidebar).
    expect(page).to have_css(".profile-image img[src*='world.png']")

    visit "#{profile_path}/edit"
    expect(page).to have_css("img[src*='world.png']")
    check 'Delete picture'
    click_button 'Save Profile'

    expect(page).to have_current_path(profile_path, ignore_query: true)
    expect(user.reload.avatar?).to be false
    expect(page).not_to have_css(".profile-image img")
  end

  # Notifications. The table (Date/Subject/Message + a per-row trash link) only renders
  # when the mailbox has messages, so seed real Mailboxer messages the same way
  # Hyrax::MessengerService does (sender.send_message).
  describe 'notifications' do
    let(:sender) { create(:user) }

    def notify(count)
      count.times do |i|
        sender.send_message(user, "Oral history interview #{i + 1} is waiting for your review.",
                            "Deposit ready for review: interview #{i + 1}")
      end
    end

    it 'lists notifications in a table with Date, Subject, and Message columns' do
      notify(2)
      visit '/notifications'

      within('table.datatable thead') do
        expect(page).to have_content('Date')
        expect(page).to have_content('Subject')
        expect(page).to have_content('Message')
      end
      expect(page).to have_content('Deposit ready for review: interview 1')
      expect(page).to have_content('Oral history interview 2 is waiting for your review.')
      expect(page).to have_css('a.itemtrash', count: 2)
    end

    it 'deletes an individual notification with its trash icon' do
      notify(2)
      visit '/notifications'

      within('tr', text: 'interview 1') { find('a.itemtrash').click }

      expect(page).to have_css('a.itemtrash', count: 1)
      expect(page).not_to have_content('Deposit ready for review: interview 1')
      expect(page).to have_content('Deposit ready for review: interview 2')
    end

    it 'deletes all notifications with Delete All' do
      notify(2)
      visit '/notifications'

      click_link 'Delete All'

      expect(page).not_to have_css('a.itemtrash')
      expect(page).to have_content('No notifications')
    end

    # Search, pagination and the total count are added client-side by DataTables.
    it 'offers search, pagination, and a total count', js: true do
      notify(12)
      visit '/notifications'

      expect(page).to have_css('.dataTables_filter input[type="search"]')
      expect(page).to have_css('.dataTables_info', text: 'of 12 entries')
      expect(page).to have_css('.dataTables_paginate')

      # Quoted, so DataTables matches the phrase; unquoted, it matches each word anywhere in the row (dates too).
      find('.dataTables_filter input[type="search"]').fill_in(with: '"interview 11"')
      expect(page).to have_css('.dataTables_info', text: '1 to 1 of 1 entries')
    end
  end
end
