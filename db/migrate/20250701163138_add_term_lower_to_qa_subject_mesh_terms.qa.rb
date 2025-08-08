# This migration comes from qa (originally 20130918141523)
class AddTermLowerToQaSubjectMeshTerms < ActiveRecord::Migration[4.2]
  def change
    add_column :qa_subject_mesh_terms, :term_lower, :string
    add_index :qa_subject_mesh_terms, :term_lower
    remove_index :qa_subject_mesh_terms, :term
  end
end
