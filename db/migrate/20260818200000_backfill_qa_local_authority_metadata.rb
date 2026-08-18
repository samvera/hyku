# frozen_string_literal: true

# Reaches tenants seeded before these columns existed without waiting for someone
# to run `rake populate_qa` against each one.
class BackfillQaLocalAuthorityMetadata < ActiveRecord::Migration[7.2]
  def up
    Qa::LocalAuthority.reset_column_information

    metadata = LocalVocabularyService.metadata_by_name

    blank = Qa::LocalAuthority.where(label: [nil, ''])
                              .or(Qa::LocalAuthority.where(description: [nil, '']))

    blank.find_each do |authority|
      LocalVocabularyService.backfill_metadata(authority, metadata.fetch(authority.name, {}))
      authority.save! if authority.changed?
    end
  end

  def down
    # Nothing to undo: the columns hold no value this migration can distinguish
    # from one a person typed.
  end
end
