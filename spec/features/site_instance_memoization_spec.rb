# frozen_string_literal: true

RSpec.describe 'Site.instance memoization on a real page render', type: :feature, clean: true, js: false do
  it 'issues at most one sites-table query to render the catalog search page' do
    expect { visit '/catalog' }
      .to make_database_queries(matching: /FROM "sites"/, count: 0..1)

    expect(page).to have_content('Search Results')
  end
end
