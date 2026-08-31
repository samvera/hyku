# frozen_string_literal: true

module Qa
  class LocalAuthority < ApplicationRecord
    NAME_FORMAT = /\A[a-z0-9][a-z0-9_-]*\z/

    # A reorder was saved from a page drawn before someone else changed the terms.
    class StaleOrder < StandardError; end

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

    # Renumbers this vocabulary's terms into the order given, 1..n.
    #
    # Ids not belonging to this vocabulary are ignored, and any term the caller left
    # out keeps its place after the ones listed — a stale page must not silently
    # drop the terms it never showed. Contiguous rather than sparse: the list a
    # depositor sees is rebuilt from these numbers, so a gap has nothing to mean.
    #
    # @param ids [Array<Integer, String>] term ids, first to last
    # @return [Integer] how many terms were renumbered
    def resequence_terms(ids, reviewed_digest = nil)
      # Locked for the read as well as the write: the positions read here decide which
      # rows the write skips, so two admins reordering from the same page could
      # otherwise interleave and leave the vocabulary with duplicate positions.
      with_lock do
        raise StaleOrder if reviewed_digest && term_state_digest != reviewed_digest

        current = local_authority_entries.ordered.pluck(:id, :position)
        listed = ids.map(&:to_i).uniq & current.map(&:first)
        trailing = current.map(&:first) - listed

        write_positions(moved_terms(listed + trailing, current.to_h))
      end
    end

    # Built the same way the import's review digest is, and from the same columns,
    # because a reorder writes updated_at for exactly this reason.
    def term_state_digest
      pairs = local_authority_entries.pluck(:uri, :updated_at)
      Digest::MD5.hexdigest(pairs.map { |uri, updated_at| "#{uri}:#{updated_at.to_f}" }.sort.join('|'))
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

    # The terms whose position actually changes, as id => new position. A drag moves
    # one term past a few others, so comparing first keeps the write proportional to
    # what moved rather than to the size of the vocabulary. Terms predating positions
    # hold NULL and so never match, which is what finally numbers them.
    def moved_terms(ordered_ids, positions)
      ordered_ids.each_with_object({}).with_index do |(id, moved), index|
        target = index + 1
        moved[id] = target unless positions[id] == target
      end
    end

    # A CASE rather than one update per term, so reversing a 500-term vocabulary is
    # one round trip rather than 500. There is no unique index on position, so the
    # rows may be written in any order without colliding part way through.
    #
    # Sliced, because the size of one statement is not bounded by what the page
    # showed: a vocabulary whose terms predate positions has every row unnumbered, so
    # its first reorder renumbers all of them — trailing terms the page never listed
    # included.
    #
    # updated_at is set explicitly, which update_all would otherwise leave alone: an
    # import's review digest is built from it, and a reorder that left it untouched
    # would let a reviewed import be confirmed and overwrite the new order.
    def write_positions(moved)
      return 0 if moved.empty?

      touched = Qa::LocalAuthorityEntry.sanitize_sql_array(['updated_at = ?', Time.current])

      moved.each_slice(Qa::LocalAuthorityEntry::BATCH_SIZE) do |batch|
        whens = batch.map do |id, position|
          Qa::LocalAuthorityEntry.sanitize_sql_array(['WHEN id = ? THEN ?', id, position])
        end

        local_authority_entries
          .where(id: batch.map(&:first))
          .update_all(Arel.sql("position = CASE #{whens.join(' ')} END, #{touched}")) # rubocop:disable Rails/SkipsModelValidations
      end

      moved.size
    end

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
