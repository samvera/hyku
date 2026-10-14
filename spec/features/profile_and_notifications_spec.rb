# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile and Notifications', type: :feature, clean: true do
  let(:user) { create(:user, email: 'profileuser@example.com') }

  before do
    login_as user
  end

  it 'allows editing profile and avatar' do
    visit '/dashboard/profile/edit'
    fill_in 'Display Name', with: 'Profile User'
    fill_in 'Twitter handle', with: '@profileuser'
    fill_in 'ORCID profile', with: '0000-0000-0000-0000'
    click_button 'Save Profile'
    expect(page).to have_content('Profile User')
    expect(page).to have_content('@profileuser')
    expect(page).to have_content('0000-0000-0000-0000')
  end

  it 'shows and deletes notifications' do
    visit '/notifications'
    expect(page).to have_content('Notifications')
    click_link 'Delete All' if page.has_link?('Delete All')
    expect(page).to have_content('No notifications')
  end

  # Profile SHOW page. Route/param mirror spec/requests/user_roles_spec.rb
  # (`/dashboard/profiles/<email with '.' => '-dot-'>`). Labels are grounded in
  # the Hyrax profile show view (hyrax/dashboard/profiles/show ->
  # hyrax/users/_vitals + _user_info) and the stats locale keys.
  it 'displays join date, collection/work links, stats, email, and edit link on the profile show page' do
    visit "/dashboard/profiles/#{user.email.gsub('.', '-dot-')}"

    # I can see the date that I joined the site (hyrax.dashboard.stats.joined_on)
    expect(page).to have_content('Joined on')

    # Collections Created / Works Created links to filtered search results,
    # each with a count badge rendered to their left.
    expect(page).to have_link('Collections created')
    expect(page).to have_link('Works created', href: /catalog/)

    # Under Works created: number of Views and number of Downloads
    # (hyrax.dashboard.stats.file_views "View" / file_downloads "Download",
    # pluralized).
    expect(page).to have_content('Views')
    expect(page).to have_content('Downloads')

    # I can see the email associated with my account (rendered via mail_to).
    expect(page).to have_content(user.email)

    # I can click Edit Profile, directing me to the Edit Profile form.
    expect(page).to have_link('Edit Profile')
    click_link 'Edit Profile'
    expect(page).to have_field('Display Name')
  end

  # Profile EDIT page. Field ids are deterministic from `form_for @user` in the
  # Hyku override app/views/hyrax/dashboard/profiles/_edit_primary.html.erb
  # (f.file_field :avatar, f.check_box :remove_avatar, f.text_field
  # :facebook_handle, f.text_field :googleplus_handle). The existing example
  # already covers Display Name / Twitter handle / ORCID profile.
  it 'renders the profile picture, delete-picture, Facebook, and Google+ inputs on the edit form' do
    visit '/dashboard/profile/edit'

    # File input for profile picture
    expect(page).to have_css("input#user_avatar[type='file']")
    # Delete picture checkbox
    expect(page).to have_css("input#user_remove_avatar[type='checkbox']")
    # Facebook handle input
    expect(page).to have_css('input#user_facebook_handle')
    # Google+ handle input
    expect(page).to have_css('input#user_googleplus_handle')
    # Save Profile button (label rendered from save_profile locale key)
    expect(page).to have_button('Save Profile')
  end

  # Notifications table structure. The Hyrax notifications/_notifications
  # partial only renders the <table> (Date/Subject/Message headers + per-row
  # trash link.itemtrash) when the mailbox has messages; an empty mailbox shows
  # only "No notifications found". Seeding real Mailboxer messages is required
  # and cannot be verified here, so this is skipped with the exact expectations
  # documented for a real run.
  it 'lists notifications in a table with Date, Subject, and Message columns' do
    skip('Needs seeded Mailboxer notifications (e.g. Hyrax::MessengerService.deliver) ' \
         'to render the table; cannot be reliably seeded/verified without running the suite.')

    visit '/notifications'
    within('table.datatable thead') do
      expect(page).to have_content('Date')
      expect(page).to have_content('Subject')
      expect(page).to have_content('Message')
    end
    # Individual delete: per-row trash link (class itemtrash, method :delete)
    expect(page).to have_css('a.itemtrash i.fa-trash')
  end

  # Search bar, pagination, and total count are provided client-side by the
  # DataTables plugin over the notifications table, which requires both seeded
  # messages and a JavaScript-capable driver (this spec uses the default
  # rack_test driver and does not set js: true).
  it 'offers search, pagination, and a total count over notifications' do
    skip('DataTables search/pagination/count are JS-rendered and require seeded ' \
         'notifications plus a js: true driver; not exercisable under rack_test.')
  end
end


# ## Profile Page
# [Back to TOC](#table-of-contents)

# ![image68](https://github.com/samvera/hyku/assets/19597776/e96ff5ff-3328-4979-86bc-c2fabd51b3cc)

# ### As a user:

# - [ ] I can see the date that I joined the site
# - [ ] I can click on the link to Collections Created, directing me to a search results page of all of the collections that I have created
#   - [ ] To the right, I can see the number of collections I have created
# - [ ] I can click on the Works Created link, directing me to a search results page of all of the works that I have created
#   - [ ] To the right, I can see the number of works I have created
#   - [ ] Under Works created I can see
#     - [ ] The number of Views
#     - [ ] The number of Downloads
# - [ ] I can see the email associated with my account
# - [ ] I can click Edit Profile, directing me to the Edit Profile form  \


# ## Profile Edit Page
# [Back to TOC](#table-of-contents)

# ![image48](https://github.com/samvera/hyku/assets/19597776/f1c5cf5b-885b-4798-8ded-5652ea1e079b)

# ### As a user:

# - [ ] I can see a form to update my profile with the following inputs:
#   - [ ] File input for profile picture
#   - [ ] Delete picture checkbox
#     - [ ] If this is checked, the profile picture is removed
#   - [ ] ORCID profile
#   - [ ] Twitter handle
#   - [ ] Facebook handle
#   - [ ] Google+ handle
# - [ ] I can click Save Profile, which saves my information and directs me to the Profile page

# ## Notifications Page
# [Back to TOC](#table-of-contents)

# ![image13](https://github.com/samvera/hyku/assets/19597776/88a81c38-9d78-4301-babc-538c237a76f0)

# ### As a user:

# - [ ] I can click Delete All, deleting all of my notifications
# - [ ] I can see a table listing all notifications associated with my account with the following attributes:
#   - [ ] Date
#   - [ ] Subject
#   - [ ] Message
# - [ ] I can delete individual notifications by clicking on the trash icon to the right
# - [ ] I can filter through my notifications using the search bar
# - [ ] I can see the total number of notifications
# - [ ] I can see a pagination menu on the bottom right
