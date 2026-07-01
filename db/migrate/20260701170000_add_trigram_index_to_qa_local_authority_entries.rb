# frozen_string_literal: true

# Qa::Authorities::Mesh (app/authorities/qa/authorities/mesh.rb) searches
# qa_local_authority_entries with `LOWER(label) LIKE '%term%'`, a leading-wildcard
# match that a normal b-tree index can't accelerate. On a tenant's full MeSH
# vocabulary (~31k rows) this is a sequential scan on every autocomplete
# keystroke. A GIN trigram index lets Postgres use it for this query without any
# change to the query itself.
class AddTrigramIndexToQaLocalAuthorityEntries < ActiveRecord::Migration[7.2]
  INDEX_NAME = 'index_qa_local_authority_entries_on_lower_label_trgm'

  def up
    unless pg_trgm_available?
      say 'pg_trgm extension is not available on this Postgres server — skipping the ' \
          'trigram index on qa_local_authority_entries. Local authority search (e.g. ' \
          'MeSH autocomplete) will still work, just without this index optimization.'
      return
    end

    execute 'CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA shared_extensions;'

    execute <<-SQL.squish
      CREATE INDEX IF NOT EXISTS #{INDEX_NAME}
      ON qa_local_authority_entries
      USING gin (lower(label) gin_trgm_ops)
    SQL
  end

  def down
    remove_index :qa_local_authority_entries, name: INDEX_NAME, if_exists: true
  end

  private

  # Checking pg_available_extensions up front lets us skip cleanly on Postgres
  # installs that don't have the contrib module, instead of a mid-deploy
  # migration failure that's hard for downstream institutions to diagnose.
  def pg_trgm_available?
    select_value("SELECT 1 FROM pg_available_extensions WHERE name = 'pg_trgm'").present?
  end
end
