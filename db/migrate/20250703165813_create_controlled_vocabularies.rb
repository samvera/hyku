class CreateControlledVocabularies < ActiveRecord::Migration[6.1]
  def change
    create_table :controlled_vocabularies do |t|
      t.string :name
      t.string :vocabulary_type
      t.string :service_class
      t.jsonb :configuration

      t.timestamps
    end
    add_index :controlled_vocabularies, :name, unique: true
    add_index :controlled_vocabularies, :vocabulary_type
  end
end
