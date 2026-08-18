# frozen_string_literal: true

# `rake populate_qa` only creates rows it doesn't already find, so a tenant
# seeded before these columns existed never gets them filled.
class BackfillQaLocalAuthorityMetadata < ActiveRecord::Migration[7.2]
  def up
    Qa::LocalAuthority.reset_column_information

    metadata = LocalVocabularyService.metadata_by_name

    blank = Qa::LocalAuthority.where(label: [nil, ''])
                              .or(Qa::LocalAuthority.where(description: [nil, '']))

    blank.find_each do |authority|
      entries = authority.local_authority_entries

      LocalVocabularyService.backfill_metadata(
        authority,
        metadata.fetch(authority.name, {}),
        term_count: entries.count,
        # Counted and sampled rather than plucked whole: a tenant's MeSH
        # vocabulary is tens of thousands of rows.
        sample_terms: entries.ordered.limit(LocalVocabularyService::SAMPLE_TERM_COUNT).pluck(:label)
      )

      authority.save! if authority.changed?
    end
  end

  def down
    # Nothing to undo: the columns hold no value this migration can distinguish
    # from one a person typed.
  end
end
