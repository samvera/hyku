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

    def self.file_based_names
      Qa::Authorities::Local.names
    rescue Qa::ConfigDirectoryNotFound => e
      Rails.logger.warn("Unable to list file-based local authorities: #{e.message}")
      []
    end

    def display_label
      label.presence || name.to_s.titleize
    end

    def source_key
      "local/#{name}"
    end
  end
end
