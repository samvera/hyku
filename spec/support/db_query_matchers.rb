# frozen_string_literal: true

DBQueryMatchers.configure do |config|
  # Exclude one-time schema-introspection queries (pg_attribute/pg_attrdef lookups
  # Rails issues to populate its column-type cache) from every make_database_queries
  # assertion - noisy, one-time overhead unrelated to the actual query fan-out any
  # given spec is guarding against.
  config.schemaless = true
end
