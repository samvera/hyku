# frozen_string_literal: true
# DOI, not Doi: the engine registers `inflect.acronym 'DOI'`, so Rails camelizes this
# migration's filename to CreateHyraxDOIPersistentIdentifiers and will not find any other
# spelling.
class CreateHyraxDOIPersistentIdentifiers < ActiveRecord::Migration[7.2]
  def change
    create_table :hyrax_doi_persistent_identifiers do |t|
      # Valkyrie resource id, as a string rather than a foreign key: Valkyrie
      # resources are not ActiveRecord rows. Nullable so a draft identifier can be
      # reserved before the work it will belong to exists.
      t.string :resource_id
      t.string :resource_type

      t.string :scheme, null: false
      t.string :provider, null: false
      t.string :value, null: false

      # Provider vocabulary, stored verbatim: DataCite's draft/registered/findable
      # and EZID's reserved/public/unavailable do not map onto a common set without
      # losing meaning.
      t.string :state

      # 'minted' or 'external'. Identifiers we did not mint must never be updated
      # or deleted at the provider.
      t.string :origin, null: false, default: 'minted'

      t.boolean :primary, null: false, default: true

      t.datetime :minted_at
      t.datetime :last_synced_at
      t.text :last_error

      t.timestamps
    end

    add_index :hyrax_doi_persistent_identifiers,
              %i[scheme provider value],
              unique: true,
              name: 'index_hyrax_doi_pids_on_scheme_provider_value'
    add_index :hyrax_doi_persistent_identifiers,
              %i[resource_id scheme],
              name: 'index_hyrax_doi_pids_on_resource_id_and_scheme'
  end
end
