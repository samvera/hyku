# frozen_string_literal: true

module Qa
  class LocalAuthority < ApplicationRecord
    NAME_FORMAT = /\A[a-z0-9][a-z0-9_-]*\z/

    has_many :local_authority_entries, dependent: :destroy

    validates :name, presence: true
    # Guarded on name_changed? so rows predating these rules stay editable.
    validates :name,
              uniqueness: { case_sensitive: false },
              format: {
                with: NAME_FORMAT,
                message: 'must be lowercase letters, numbers, underscores and hyphens, ' \
                         'starting with a letter or number'
              },
              if: -> { name_changed? && name.present? }

    scope :ordered, -> { order(Arel.sql("COALESCE(NULLIF(label, ''), name)")) }

    def display_label
      label.presence || name.to_s.titleize
    end

    # The value staff paste into a metadata profile's controlled_values sources.
    # Bare, matching how the file-based vocabularies are already cited there.
    def source_key
      name
    end
  end
end
