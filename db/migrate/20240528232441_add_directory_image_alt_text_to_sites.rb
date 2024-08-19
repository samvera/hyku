# frozen_string_literal: true

class AddDirectoryImageAltTextToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :directory_image_alt_text, :string unless column_exists?(:sites, :directory_image_alt_text)
  end
end
