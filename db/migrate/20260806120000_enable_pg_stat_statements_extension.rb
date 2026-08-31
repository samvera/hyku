# frozen_string_literal: true

# Backfills pg_stat_statements into shared_extensions for tenants/databases that
# already existed before this migration
class EnablePgStatStatementsExtension < ActiveRecord::Migration[7.2]
  def up
    unless pg_stat_statements_preloaded?
      say 'pg_stat_statements is not in shared_preload_libraries on this Postgres server ' \
          '(requires an infra-side restart to load) - skipping. Slow-query logging via ' \
          'log_min_duration_statement is unaffected either way.'
      return
    end

    execute 'CREATE EXTENSION IF NOT EXISTS pg_stat_statements SCHEMA shared_extensions;'
  end

  def down
    execute 'DROP EXTENSION IF EXISTS pg_stat_statements;'
  end

  private

  # shared_preload_libraries is set and loaded at the Postgres server level (a
  # restart, not something this migration can do) - check it up front instead of
  # a mid-deploy migration failure on any cluster that hasn't been restarted yet.
  def pg_stat_statements_preloaded?
    select_value(
      "SELECT current_setting('shared_preload_libraries', true) LIKE '%pg_stat_statements%'"
    )
  end
end
