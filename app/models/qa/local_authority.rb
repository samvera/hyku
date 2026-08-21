# frozen_string_literal: true

module Qa
  class LocalAuthority < ApplicationRecord
    NAME_FORMAT = /\A[a-z0-9][a-z0-9_-]*\z/

    has_many :local_authority_entries, dependent: :destroy

    # Set by the dashboard only, so the mesh import task can still create its own row
    # under a name staff are not allowed to use.
    attr_accessor :staff_created

    # Create only: a metadata profile cites the name and works store terms found
    # through it, so a later relabel must not move it.
    before_validation :derive_name_from_label, on: :create

    validates :name, presence: true
    # Guarded on name_changed? so rows predating these rules stay editable. The
    # message names the key because it is derived: "Café Terms" and "Cafe Terms" both
    # give `cafe_terms`, so a label collision is not obvious from the label.
    validates :name,
              uniqueness: { case_sensitive: false, message: :taken_as_source_key },
              format: {
                with: NAME_FORMAT,
                message: 'must be lowercase letters, numbers, underscores and hyphens, ' \
                         'starting with a letter or number'
              },
              if: -> { name_changed? && name.present? }

    validate :name_is_not_already_an_authority, if: -> { staff_created && name.present? }

    scope :ordered, -> { order(Arel.sql("COALESCE(NULLIF(label, ''), name)")) }

    def display_label
      label.presence || name.to_s.titleize
    end

    # The value staff paste into a metadata profile's controlled_values sources.
    # Bare, matching how the file-based vocabularies are already cited there.
    def source_key
      name
    end

    # Use underscores to match the vocabularies already shipped (`learning_resource_types`).
    def self.name_for(label)
      label.to_s.parameterize(separator: '_')
    end

    private

    def derive_name_from_label
      self.name = self.class.name_for(label) if name.blank? && label.present?
    end

    # The form helper resolves a row before a remote service, so a row named
    # `geonames` would hijack that field. Taking a yaml name is allowed on purpose: the
    # row is used in place of the file, which is how a tenant owns a shipped list.
    def name_is_not_already_an_authority
      return unless reserved_names.include?(name.to_s.downcase)

      errors.add(:name, :already_an_authority)
    end

    def reserved_names
      (remote_source_keys + cached_authority_names).map(&:downcase).uniq
    end

    # Service keys only: the format rule rejects a slash first, so `service/vocabulary`
    # forms could never match here.
    def remote_source_keys
      Qa::AuthorityRegistry.remote_services.keys
    end

    # Authorities whose terms a re-import replaces wholesale, mesh being the case in
    # hand.
    def cached_authority_names
      registered_names.select { |registered| cached_authority?(registered) }
    end

    def registered_names
      Qa::Authorities::Local.registry.keys.map(&:to_s)
    rescue StandardError => e
      Rails.logger.warn("Unable to list the registered authorities: #{e.message}")
      []
    end

    # Rescued per name, not around the list: one unresolvable authority would
    # otherwise reserve nothing, letting a row named `mesh` through. An authority that
    # does not answer is treated as owned here, so a name is reserved only on purpose.
    def cached_authority?(name)
      authority = Qa::Authorities::Local.subauthority_for(name)
      return false unless authority.respond_to?(:locally_owned?)

      !authority.locally_owned?
    rescue StandardError => e
      Rails.logger.debug { "Unable to resolve #{name} while listing cached authorities: #{e.message}" }
      false
    end
  end
end
