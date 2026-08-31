# frozen_string_literal: true

namespace :db do
  desc 'Also create shared_extensions Schema'
  task extensions: :environment do
    # Create Schema
    ActiveRecord::Base.connection.execute 'CREATE SCHEMA IF NOT EXISTS shared_extensions;'
    # Enable Hstore
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS HSTORE SCHEMA shared_extensions;'
    # Enable UUID-OSSP
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA shared_extensions;'
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA shared_extensions;'
    # Enable pg_trgm (used for trigram-indexed local authority search, e.g. MeSH)
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "pg_trgm" SCHEMA shared_extensions;'
    # Enable pg_stat_statements (slow-query / N+1 diagnostics).
    # Skip silently if pg_stat_statements hasn't been loaded via a restart yet on this database.
    if ActiveRecord::Base.connection.select_value(
      "SELECT current_setting('shared_preload_libraries', true) LIKE '%pg_stat_statements%'"
    )
      ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" SCHEMA shared_extensions;'
    end
    # Grant usage to public
    ActiveRecord::Base.connection.execute 'GRANT usage ON SCHEMA shared_extensions to public;'
  end
end

Rake::Task["db:create"].enhance do
  Rake::Task["db:extensions"].invoke
end

Rake::Task["db:test:purge"].enhance do
  Rake::Task["db:extensions"].invoke
end
