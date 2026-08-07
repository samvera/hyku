# frozen_string_literal: true

require 'db_query_matchers'

# spec/features/catalog_query_count_spec.rb covers the same "doesn't scale with
# result count" property using fake Solr-only documents (random UUIDs with no
# backing orm_resources row) - useful, but it never exercises the real per-result
# Valkyrie find_by/orm_resources lookup that a genuine search hit triggers. The
# pg_stat_statements investigation in notch8-ops found a real /catalog request
# issuing ~100 individual `SELECT "orm_resources".* WHERE id = $1` queries, one per
# result - Bullet doesn't catch this (it's an explicit find call, not an unloaded AR
# association), so this is a targeted regression guard using real, persisted works.
RSpec.describe 'Catalog query performance with real, persisted works', type: :feature, clean: true, js: false do
  let(:admin) { create(:admin) }
  let(:solr) { Blacklight.default_index.connection }
  let(:works) { Array.new(6) { |i| create(:work, title: ["Real Work Query Count #{i}"], user: admin) } }

  before do
    # Exclude one-time schema-introspection queries (pg_attribute/pg_attrdef lookups
    # Rails issues to populate its column-type cache) - noisy, one-time overhead
    # unrelated to the per-result query fan-out this spec is actually guarding against.
    DBQueryMatchers.configuration.schemaless = true

    login_as admin
    works.each { |work| solr.add(work.to_solr) }
    solr.commit
  end

  after { DBQueryMatchers.reset_configuration }

  after do
    solr.delete_by_query('title_tesim:Real\ Work\ Query\ Count*')
    solr.commit
  end

  it 'does not fire an unbounded number of queries for a page of real search results' do
    # Observed 281 (schemaless) for 6 real works on 2026-08-07 - ~25% headroom above
    # that, not a guess. Consistent with catalog_query_count_spec's own calibration
    # (< 400 for 8 mixed fake-doc results, a similar per-result ratio).
    expect { visit '/catalog?q=Real+Work+Query+Count' }
      .to make_database_queries(count: 0..350)

    expect(page).to have_content('Real Work Query Count 0')
  end
end
