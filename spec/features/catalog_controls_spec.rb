# frozen_string_literal: true

require 'rails_helper'

# Manual test plan: "Catalog (Search Results) Page" — the search bar, the Sort by /
# per-page / layout filters, New Search (clears active filters), the facet metadata
# menus, and pagination. Works must be public to appear in the anonymous catalog.
#
# Speed: works are Valkyrie GenericWorkResources (persisted to Postgres rather than
# Fedora; Hyku's primary work type), and each example creates only as many as it needs --
# just the pagination example needs more than one page.
RSpec.describe 'Catalog controls', type: :feature, clean: true, flexible: :either do
  let!(:control_work) { public_work(title: 'Catalog control work', keyword: ['catalog test', 'catalog-unique']) }

  def public_work(title:, keyword: ['catalog test'])
    FactoryBot.valkyrie_create(:generic_work_resource, title: [title], keyword:, visibility_setting: 'open')
  end

  def create_page_works(count)
    count.times { |index| public_work(title: "Catalog page #{index}") }
  end

  let(:per_page) { CatalogController.blacklight_config.default_per_page }

  it 'searches from the search bar and returns the matching work' do
    visit '/catalog'

    fill_in 'search-field-header', with: 'Catalog control work'
    click_button 'search-submit-header'

    # Assert the work is an actual result link, not merely the echoed query text.
    expect(page).to have_css('.search-result-title a', text: 'Catalog control work')
  end

  it 'customizes the search results by selecting different filters (Sort by, number of records per page, layout)' do
    # One more page of works than fits, plus the work created above.
    create_page_works(per_page + 2)
    visit '/catalog?search_field=all_fields&q=catalog'
    expect(page).to have_css('.search-result-title a', count: per_page)

    within('#sort-dropdown') { click_link 'Title' }
    titles = page.all('.search-result-title a').map(&:text)
    expect(titles).to eq(titles.sort)

    within('#per_page-dropdown') { click_link '20' }
    expect(page).to have_css('.search-result-title a', count: per_page + 3)

    within('.view-type-group') { click_link 'Gallery' }
    expect(page).to have_css('#documents.documents-gallery')
    expect(page).not_to have_css('#documents.documents-list')
  end

  it 'limits results with a facet menu and clears it via New Search' do
    create_page_works(2)
    visit '/catalog?search_field=all_fields&q=catalog'
    expect(page).to have_css('.facets')

    # Selecting the unique keyword facet narrows the results down to just that work.
    within('#facet-keyword_sim') { click_link 'catalog-unique' }
    expect(page).to have_css('.search-result-title a', text: 'Catalog control work')
    expect(page).not_to have_css('.search-result-title a', text: 'Catalog page 0')
    expect(page).to have_content('Remove constraint')
    expect(page).to have_content('1 entry found')

    # New Search (Hyku's label for Blacklight's Start Over) removes active filters,
    # bringing the other works back.
    click_link 'New Search'
    expect(page).not_to have_content('Remove constraint')
    expect(page).to have_css('.search-result-title a', text: 'Catalog page 0')
    expect(page).to have_css('.search-result-title a', text: 'Catalog control work')
  end

  it 'paginates when results span multiple pages' do
    # More than one page of results, plus the work created above.
    create_page_works(per_page + 2)
    total = per_page + 3
    visit '/catalog?search_field=all_fields&q=catalog'

    expect(page).to have_css('.pagination')
    expect(page).to have_content("1 - #{per_page} of #{total}")

    find("a[rel='next']", match: :first).click
    expect(page).to have_content("#{per_page + 1} - #{total} of #{total}")
  end
end
