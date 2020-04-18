class AddContactEmailToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :contact_email, :string
  end
end
