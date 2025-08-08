# This migration comes from qa (originally 20130917200611)
class CreateQaSubjectMeshTerms < ActiveRecord::Migration[4.2]
  def change
    create_table :qa_subject_mesh_terms do |t|
      t.string :term_id
      t.string :term
      t.text :synonyms
    end
    add_index :qa_subject_mesh_terms, :term_id
    add_index :qa_subject_mesh_terms, :term
  end
end
