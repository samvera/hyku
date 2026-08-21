# frozen_string_literal: true

# Bulk-imports terms into a locally managed vocabulary from an uploaded CSV or
# yaml file. Nothing is written until apply!: the controller shows plan for
# review first, then rebuilds the import from the re-submitted file to apply.
class ControlledVocabularyImport
  MAX_BYTES = 5.megabytes
  MAX_ROWS = 50_000
  BATCH_SIZE = 1_000

  def initialize(content:, filename:, vocabulary:)
    @content = content
    @filename = filename
    @vocabulary = vocabulary
  end

  def plan
    @plan ||= Plan.new(Parser.call(@content, @filename), @vocabulary)
  end

  # upsert_all skips validations, which hold by construction here: uri is the
  # conflict key so it is never reassigned, the parser rejects in-file
  # duplicates and defaults blank ids to the label, and active is never nil.
  def apply!
    raise ArgumentError, 'cannot apply a plan with errors' unless plan.valid?

    ActiveRecord::Base.transaction do
      plan.upsert_rows.each_slice(BATCH_SIZE) do |batch|
        Qa::LocalAuthorityEntry.upsert_all(batch, unique_by: %i[local_authority_id uri]) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
