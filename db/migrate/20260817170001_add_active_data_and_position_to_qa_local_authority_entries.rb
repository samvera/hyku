# frozen_string_literal: true

class AddActiveDataAndPositionToQaLocalAuthorityEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :qa_local_authority_entries, :active, :boolean, default: true, null: false
    add_column :qa_local_authority_entries, :data, :jsonb, default: {}, null: false
    add_column :qa_local_authority_entries, :position, :integer

    add_index :qa_local_authority_entries,
              %i[local_authority_id active],
              name: 'index_qa_local_authority_entries_on_authority_and_active'

    add_index :qa_local_authority_entries,
              %i[local_authority_id position label],
              name: 'index_qa_local_authority_entries_on_authority_and_sequence'
  end
end
