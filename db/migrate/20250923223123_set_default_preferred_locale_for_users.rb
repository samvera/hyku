class SetDefaultPreferredLocaleForUsers < ActiveRecord::Migration[6.1]
  def up
    execute "UPDATE users SET preferred_locale = 'en' WHERE preferred_locale IS NULL OR preferred_locale = ''"
    
    change_column_default :users, :preferred_locale, 'en'
  end

  def down
    change_column_default :users, :preferred_locale, nil
  end
end
