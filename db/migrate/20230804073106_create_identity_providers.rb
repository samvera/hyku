class CreateIdentityProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :identity_providers do |t|
      t.string :name
      t.string :provider
      t.jsonb :options
      t.string :logo_image
      t.string :logo_image_text
      t.timestamps
    end
  end
end
