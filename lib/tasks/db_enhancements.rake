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
