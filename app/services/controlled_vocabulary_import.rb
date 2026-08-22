# frozen_string_literal: true

# Bulk-imports terms into a locally managed vocabulary from an uploaded CSV or
# yaml file. Nothing is written until apply!: the controller shows plan for
# review first, then rebuilds the import from the re-submitted file to apply.
class ControlledVocabularyImport
  MAX_BYTES = 5.megabytes
  MAX_ROWS = 50_000
  BATCH_SIZE = 1_000

  # The vocabulary changed between the review and the confirmation, so applying would
  # overwrite something the reviewer never saw.
  class Stale < StandardError; end

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
  #
  # Takes the lock a reorder takes, and rebuilds the rows under it: a full-file import
  # rewrites every position, and the reviewed plan was read before the lock was held.
  # The digest turns that re-read into a check, so an order set after the review is not
  # overwritten. with_lock reloads, so the rebuilt plan reads the terms afresh.
  #
  # @param reviewed_digest [String, nil] the digest shown at review, when there is one
  # @raise [Stale] when the vocabulary changed after it was reviewed
  def apply!(reviewed_digest = nil)
    raise ArgumentError, 'cannot apply a plan with errors' unless plan.valid?

    @vocabulary.with_lock do
      current = Plan.new(Parser.call(@content, @filename), @vocabulary)
      raise Stale if reviewed_digest && current.state_digest != reviewed_digest

      current.upsert_rows.each_slice(BATCH_SIZE) do |batch|
        Qa::LocalAuthorityEntry.upsert_all(batch, unique_by: %i[local_authority_id uri]) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
