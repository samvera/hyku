# frozen_string_literal: true

module Qa
  # `uri` holds the term identifier and is the value Bulkrax imports. It is not
  # required to be an actual URI.
  class LocalAuthorityEntry < ApplicationRecord
    # How many rows one bulk statement against this table may carry. Both writers
    # that use it — an import saving its terms, and a reorder renumbering them —
    # hold the same lock while they run, so neither should build a statement
    # larger than the other's.
    BATCH_SIZE = 1_000

    belongs_to :local_authority

    store_accessor :data, :alt_labels, :definition

    before_validation { self.uri = nil if uri.blank? }
    # After the blanking above, or the label would be wiped straight away.
    before_validation :default_uri_to_label, on: :create
    before_create :default_position_to_last

    validates :uri, presence: true, on: :create
    validates :uri, uniqueness: { scope: :local_authority_id }, allow_nil: true
    validate :uri_is_not_reassigned, on: :update

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :ordered, -> { order(:position, :label) }

    private

    def uri_is_not_reassigned
      return unless uri_changed?

      errors.add(:uri, 'cannot be changed, because works store it as the term id')
    end

    def default_uri_to_label
      self.uri = label if uri.blank?
    end

    # Counted as well as measured: rows predating this hold NULL, so the highest
    # assigned position can still be below them and reusing it would collide once
    # they are numbered.
    def default_position_to_last
      return if position.present? || local_authority_id.blank?

      siblings = self.class.where(local_authority_id: local_authority_id)
      self.position = [siblings.maximum(:position).to_i, siblings.count].max + 1
    end
  end
end
