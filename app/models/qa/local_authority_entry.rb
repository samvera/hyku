# frozen_string_literal: true

module Qa
  # `uri` holds the term identifier and is the value Bulkrax imports. It is not
  # required to be an actual URI.
  class LocalAuthorityEntry < ApplicationRecord
    belongs_to :local_authority

    store_accessor :data, :alt_labels, :definition

    before_validation { self.uri = nil if uri.blank? }
    # After the blanking above, or the label would be wiped straight away.
    before_validation :default_uri_to_label, on: :create

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
  end
end
