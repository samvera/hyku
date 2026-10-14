# frozen_string_literal: true

class ScopeQaLocalAuthorityEntryUriUniqueness < ActiveRecord::Migration[7.2]
  GLOBAL_INDEX = 'index_qa_local_authority_entries_on_uri'
  SCOPED_INDEX = 'index_qa_local_authority_entries_on_authority_and_uri'

  def up
    remove_index :qa_local_authority_entries, name: GLOBAL_INDEX, if_exists: true
    add_index :qa_local_authority_entries, %i[local_authority_id uri], unique: true, name: SCOPED_INDEX
  end

  # Reverting fails if two vocabularies have since been given a term with the
  # same id, which this migration is what permits.
  def down
    remove_index :qa_local_authority_entries, name: SCOPED_INDEX, if_exists: true
    add_index :qa_local_authority_entries, :uri, unique: true, name: GLOBAL_INDEX
  end
end
