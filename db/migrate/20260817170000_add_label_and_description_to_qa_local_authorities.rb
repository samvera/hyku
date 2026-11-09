# frozen_string_literal: true

class AddLabelAndDescriptionToQaLocalAuthorities < ActiveRecord::Migration[7.2]
  def change
    add_column :qa_local_authorities, :label, :string
    add_column :qa_local_authorities, :description, :text
  end
end
