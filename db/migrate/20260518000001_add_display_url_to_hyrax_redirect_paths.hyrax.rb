class AddDisplayUrlToHyraxRedirectPaths < ActiveRecord::Migration[7.2]
  def change
    add_column :hyrax_redirect_paths, :display_url, :boolean, default: false, null: false
  end
end
