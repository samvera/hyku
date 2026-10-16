# frozen_string_literal: true

require 'rails_helper'

# Manual test plan: "Catalog (Search Results) Page" — the search bar, the Sort by /
# per-page / layout filters, New Search (clears active filters), the facet metadata
# menus, and pagination. Works must be public to appear in the anonymous catalog.
RSpec.describe 'Catalog controls', type: :feature, clean: true do
  let!(:control_work) do
    create(:generic_work, :public,
           title: ['Catalog control work'],
           keyword: ['catalog test', 'catalog-unique'])
  end

  before do
    # More than one page of results (the catalog defaults to 10 per page).
    12.times do |index|
      create(:generic_work, :public, title: ["Catalog page #{index}"], keyword: ['catalog test'])
    end
  end

  it 'searches from the search bar and returns the matching work' do
    visit '/catalog'

    fill_in 'search-field-header', with: 'Catalog control work'
    click_button 'search-submit-header'

    # Assert the work is an actual result link, not merely the echoed query text.
    expect(page).to have_css('.search-result-title a', text: 'Catalog control work')
  end

  it 'customizes results with the Sort by, per-page, and layout controls' do
    visit '/catalog?search_field=all_fields&q=catalog'

    within('#sort-dropdown') { click_link 'Title' }
    expect(page).to have_css('#sort-dropdown a.active', text: 'Title')

    within('#per_page-dropdown') { click_link '20' }
    expect(page).to have_css('#per_page-dropdown a.active', text: '20')

    within('.view-type-group') { click_link 'Gallery' }
    expect(page).to have_css('a.view-type-gallery.active')
  end

  it 'limits results with a facet menu and clears it via New Search' do
    visit '/catalog?search_field=all_fields&q=catalog'
    expect(page).to have_css('.facets')

    # Selecting the unique keyword facet narrows the 13 results down to just that work.
    within('#facet-keyword_sim') { click_link 'catalog-unique' }
    expect(page).to have_css('.search-result-title a', text: 'Catalog control work')
    expect(page).to have_content('Remove constraint')
    expect(page).to have_content('1 entry found')

    # New Search (Hyku's label for Blacklight's Start Over) removes active filters,
    # restoring the full result set.
    click_link 'New Search'
    expect(page).not_to have_content('Remove constraint')
    expect(page).to have_content('1 - 10 of 13')
  end

  it 'paginates when results span multiple pages' do
    visit '/catalog?search_field=all_fields&q=catalog'

    expect(page).to have_css('.pagination')
    expect(page).to have_content('1 - 10 of 13')

    find("a[rel='next']", match: :first).click
    expect(page).to have_content('11 - 13 of 13')
  end
end

# ## Catalog (Search Results) Page
# [Back to TOC](#table-of-contents)

# ![image65](https://github.com/samvera/hyku/assets/19597776/6127f7ae-633d-4613-8b51-26268fb67efa)

# ### As a user:

# - [ ] I can see a search bar
# - [ ] I can customize the search results by selecting different filters (Sort by, number of records per page, layout)
# - [ ] I can click Start Over, removing all active filters
# - [ ] If there are multiple pages, I can see a pagination menu at the bottom of the page
# - [ ] I can limit my search by selecting from the metadata dropdown menus on the left