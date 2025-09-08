# This migration comes from qa (originally 20130918141523)
class AddTermLowerToQaSubjectMeshTerms < ActiveRecord::Migration[4.2]
  def change
    add_column :qa_subject_mesh_terms, :term_lower, :string
    
    # Backfill the term_lower column with lowercase values from the term column
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE qa_subject_mesh_terms
          SET term_lower = LOWER(term)
        SQL
      end
    end
    
    add_index :qa_subject_mesh_terms, :term_lower
    remove_index :qa_subject_mesh_terms, column: :term
  end
end
