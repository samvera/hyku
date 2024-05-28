class CreateDomainNames < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:domain_names)
      create_table :domain_names do |t|
        t.references :account
        t.string :cname
        t.boolean :is_active, default: true
        t.boolean :is_ssl_enabled, default: false

        t.timestamps
      end
    end
  end
end
