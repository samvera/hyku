# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FileSet Show and Actions', type: :feature, js: true, clean: true do
  let(:admin_user) { create(:admin) }
  let(:file_set) { FactoryBot.create(:file_set, title: ['Test FileSet']) }

  before do
    login_as admin_user
  end

  it 'shows file details, allows download, edit, delete, and single-use link' do
    visit "/concern/file_sets/#{file_set.id}"
    expect(page).to have_content('Test FileSet')
    expect(page).to have_link('Download')
    click_link 'Download'
    # Download check is limited in feature specs
    click_link 'Edit this File'
    fill_in 'Title', with: 'Updated FileSet'
    click_button 'Save'
    expect(page).to have_content('Updated FileSet')
    click_link 'Delete this File'
    expect(page).not_to have_content('Updated FileSet')
    visit "/concern/file_sets/#{file_set.id}"
    click_link 'Single-Use Link to File' if page.has_link?('Single-Use Link to File')
    expect(page).to have_content('Single-Use Link') if page.has_content?('Single-Use Link')
  end

  # Public-facing "As a user" items from the Manual Test Plan. The bare :file_set
  # factory has no read_groups, so the file set is restricted (private) and cannot be
  # viewed anonymously; these run under the logged-in admin against the same show page
  # the existing example already loads.
  describe 'the show page contents (as a logged-in user)' do
    before { visit "/concern/file_sets/#{file_set.id}" }

    it "shows the file's title and visibility badge" do
      expect(page).to have_selector('h1', text: 'Test FileSet')
      # hyrax/file_sets/_file_set_title renders presenter.permission_badge; a file set
      # with no read_groups is "restricted", whose badge text is "Private".
      expect(page).to have_css('.badge', text: 'Private')
    end

    it 'shows the media display area with a download link' do
      # No binary is ingested, so hyrax/file_sets/media_display/_default renders.
      expect(page).to have_content('No preview available')
      # Every media_display download partial renders id="file_download"; the default
      # partial's label resolves to hyrax.file_set.show.download ("Download the file").
      expect(page).to have_css('a#file_download')
      expect(page).to have_link('Download the file')
    end

    it 'renders a thumbnail for the file' do
      skip('A real thumbnail requires an ingested image binary and a generated ' \
           'derivative. The bare :file_set factory has no content, so the default ' \
           'media partial shows "No preview available" instead of an <img> thumbnail.')
    end

    it 'shows a File Details table with basic file information' do
      # hyrax/file_sets/_show_details (rendered via presenter.show_partials).
      expect(page).to have_selector('h2', text: 'File Details')
      expect(page).to have_selector('dl.file-show-details')
      expect(page).to have_content('Depositor')
      expect(page).to have_content('Date Uploaded')
      expect(page).to have_content('Date Modified')
      expect(page).to have_content('Fixity Check')
    end

    it 'shows a User Activity table' do
      # hyrax/users/_activity_log renders table#activity with a "User Activity" header.
      expect(page).to have_selector('table#activity')
      expect(page).to have_selector('table#activity th', text: 'User Activity')
      # No analytics events exist for a freshly created bare file set.
      expect(page).to have_content('No user activity')
    end

    it 'shows social media share links' do
      # hyrax/base/_social_media renders Facebook / Twitter / Tumblr share links.
      expect(page).to have_css('.social-media')
      expect(page).to have_css("a[href*='facebook.com/sharer']")
      expect(page).to have_css("a[href*='twitter.com/intent']")
      expect(page).to have_css("a[href*='tumblr.com']")
    end
  end

  # "As an admin" single-use link item. The existing example clicks this link only
  # behind an `if page.has_link?` guard (making its assertion vacuous when the link is
  # absent); this asserts the control's presence unconditionally.
  describe 'the single-use link control (as an admin)' do
    it 'exposes the Single-Use Link to File control' do
      visit "/concern/file_sets/#{file_set.id}"
      # hyrax/file_sets/_single_use_links renders only when the presenter is editable;
      # an admin is an editor.
      expect(page).to have_selector('h3', text: 'Single-Use Links')
      # Hyku overrides hyrax.single_use_links.button to "Single-Use Link to File".
      expect(page).to have_link('Single-Use Link to File')
    end
  end
end


# ## FileSet Show Page
# [Back to TOC](#table-of-contents)

# ![image26](https://github.com/samvera/hyku/assets/19597776/f7d9ad7b-954d-4a25-836e-8b132660c38f)

# ### As a user:

# - [ ] I can see the file’s title, thumbnail and visibility
# - [ ] I can download the file from the Download Image link
# - [ ] I can see a table of File Details displaying basic information regarding the file
# - [ ] I can see a table of User Activity relating to the depositor / file
# - [ ] I can see icons to share the file on various social media platforms
# ### As an admin:

# - [ ] I can click Edit this File to edit the file
# - [ ] I can click Delete this File to delete the file
# - [ ] I can generate single-use download links by clicking Single-Use Link to File