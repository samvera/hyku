# frozen_string_literal: true

require 'rails_helper'

# These tests appear to fail because of concurrency; namely Flipflop features are being toggled on
# and off.
RSpec.xdescribe 'Admin can select feature flags', type: :feature, js: true, clean: true, cohort: 'bravo' do
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }
  let(:account) { FactoryBot.create(:account) }

  # rubocop:disable RSpec/LetSetup
  let!(:work) do
    create(:generic_work,
           title: ['Pandas'],
           keyword: ['red panda', 'giant panda'],
           user: admin)
  end

  let!(:collection) do
    create(:collection,
           title: ['Pandas'],
           description: ['Giant Pandas and Red Pandas'],
           user: admin,
           members: [work])
  end

  let!(:feature) { FeaturedWork.create(work_id: work.id) }

  # rubocop:enable RSpec/LetSetup

  context 'as a repository admin' do
    skip 'TODO: This consistently fails the CI pipeline, but passes locally. https://github.com/notch8/palni-palci/issues/933'
    it 'has a setting for featured works' do
      login_as admin
      visit 'admin/features'
      expect(page).to have_content 'Show featured works'
      find("tr[data-feature='show-featured-works']").find_button('off').click
      visit '/'
      expect(page).to have_content 'Recently Uploaded'
      expect(page).to have_content 'Pandas'
      expect(page).not_to have_content 'Featured Works'
      visit 'admin/features'
      find("tr[data-feature='show-featured-works']").find_button('on').click
      visit '/'
      expect(page).to have_content 'Featured Works'
      expect(page).to have_content 'Pandas'
    end

    skip 'TODO: This consistently fails the CI pipeline, but passes locally. https://github.com/notch8/palni-palci/issues/933'
    it 'has a setting for recently uploaded' do
      login_as admin
      visit 'admin/features'
      expect(page).to have_content 'Show recently uploaded'
      find("tr[data-feature='show-recently-uploaded']").find_button('off').click
      visit '/'
      expect(page).not_to have_content 'Recently Uploaded'
      expect(page).to have_content 'Pandas'
      expect(page).to have_content 'Featured Works'
      visit 'admin/features'
      find("tr[data-feature='show-recently-uploaded']").find_button('on').click
      visit '/'
      expect(page).to have_content 'Recently Uploaded'
      expect(page).to have_content 'Pandas'
      click_link 'Recently Uploaded'
      expect(page).to have_css('div#recently_uploaded')
    end

    skip 'TODO: This consistently fails the CI pipeline, but passes locally. https://github.com/notch8/palni-palci/issues/933'
    it 'has settings for the default PDF viewer with a custom toggle switch' do
      login_as admin
      visit 'admin/features'
      expect(page).to have_selector('span.enabled', text: 'PDF.js')
      find("tr[data-feature='default-pdf-viewer']").find_button('UV').click
      expect(page).to have_selector('span.disabled', text: 'UV')
      find("tr[data-feature='default-pdf-viewer']").find_button('PDF.js').click
      expect(page).to have_selector('span.enabled', text: 'PDF.js')
    end
  end

  context 'when all home tabs and share work features are turned off' do
    skip 'TODO: This consistently fails the CI pipeline, but passes locally. https://github.com/notch8/palni-palci/issues/933'
    it 'the page only shows the collections tab' do
      login_as admin
      visit 'admin/features'
      find("tr[data-feature='show-featured-works']").find_button('off').click
      find("tr[data-feature='show-recently-uploaded']").find_button('off').click
      find("tr[data-feature='show-featured-researcher']").find_button('off').click
      find("tr[data-feature='show-share-button']").find_button('off').click
      visit '/'
      expect(page).not_to have_content 'Recently Uploaded'
      expect(page).not_to have_content 'Featured Researcher'
      expect(page).not_to have_content 'Featured Works'
      expect(page).not_to have_content 'Share your work'
      expect(page).not_to have_content 'Terms of Use'
      expect(page).to have_css('div.home-content')
      expect(page).to have_content 'Explore Collections'
    end
  end
end
