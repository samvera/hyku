# frozen_string_literal: true

# Assembles every authority a metadata profile can cite into one list, so staff
# can see what is available to put in `controlled_values.sources` without reading
# the code.
#
# Four origins:
#   :database — rows this tenant owns, whether staff created them or a seed did
#   :cached   — rows holding a copy of an external vocabulary, replaced on import
#   :file     — config/authorities/*.yml, deployment-wide
#   :remote   — external services (LOC, Getty, FAST), deployment-wide
#
# Only :database rows are editable, and only once the row exists — see Entry.
#
# TODO: over the ClassLength limit while Entry and the four assemblers live here.
# Extract them once term editing settles the shape.
# rubocop:disable Metrics/ClassLength
class ControlledVocabularyCatalog
  # Editable first, then read-only local, then the external services.
  ORIGIN_ORDER = { database: 0, cached: 1, file: 2, remote: 3 }.freeze

  Entry = Struct.new(:source_key, :label, :origin, :description, :term_count,
                     :vocabulary, :provider, :configured, :import_task,
                     keyword_init: true) do
    def stored_locally?
      origin == :database || origin == :cached
    end

    # Not staff's to change: the next import replaces every row, and the identifiers
    # belong to the upstream authority.
    def cached?
      origin == :cached
    end

    # Having no terms is not a reason to withhold editing — an empty vocabulary is
    # where the first term gets added. What is needed is the row itself, which a
    # registered authority may not have yet.
    def editable?
      origin == :database && vocabulary.present?
    end

    # Anything whose terms are stored here, once the row exists, plus the yaml
    # vocabularies. Remote services are not enumerable, so they never open.
    def viewable?
      (stored_locally? && vocabulary.present?) || origin == :file
    end

    # nil means the authority needs no credentials, so only a known-missing one is
    # reported unconfigured.
    def configured?
      configured != false
    end

    def awaiting_import?
      import_task.present? && term_count.to_i.zero?
    end
  end

  class << self
    # Remote entries sort by provider so services stay together: a bare "Corporate"
    # or "Master" only makes sense next to the service it belongs to.
    #
    # @return [Array<Entry>]
    def all
      (database + file_based + remote).sort_by do |entry|
        [ORIGIN_ORDER.fetch(entry.origin, 9),
         entry.provider.to_s.downcase,
         entry.label.downcase]
      end
    end

    def database
      vocabularies = Qa::LocalAuthority.ordered.to_a
      # One grouped count rather than one per vocabulary.
      totals = Qa::LocalAuthorityEntry.where(local_authority: vocabularies).group(:local_authority_id).count

      entries = vocabularies.map { |vocabulary| database_entry(vocabulary, totals) }

      (entries + unimported_local).sort_by { |e| e.label.downcase }
    end

    # Excludes names already backed by a database row: the row is what staff see
    # and edit, so listing both would imply two separate vocabularies.
    def file_based
      claimed = Qa::LocalAuthority.pluck(:name).map(&:to_s)

      (file_based_names - claimed).map do |name|
        Entry.new(source_key: name,
                  label: name.titleize,
                  origin: :file,
                  term_count: file_term_count(name))
      end
    end

    # Built from the qa gem rather than a hand-maintained list, so the page reflects
    # what qa can actually resolve. Term counts are unknowable without querying the
    # service, so they stay nil.
    def remote
      Qa::AuthorityRegistry.remote_services.flat_map do |provider, klass|
        configured = remote_configured?(provider)

        Qa::AuthorityRegistry.subauthorities_of(klass).map do |subauthority|
          remote_entry(provider, subauthority, configured)
        end
      end
    end

    # @raise [ActiveRecord::RecordNotFound] so an unknown key 404s rather than
    #   rendering an empty page.
    def find!(source_key)
      all.detect { |entry| entry.source_key == source_key.to_s } ||
        raise(ActiveRecord::RecordNotFound, "No controlled vocabulary named #{source_key}")
    end

    # Terms for any local vocabulary, whether a database row or a yaml file backs
    # it: Qa::Authorities::LocalVocabulary resolves both and returns the same shape.
    # Remote authorities are not enumerable, so they get nothing.
    #
    # @return [Array<Hash>, nil] each with id, label, and active
    # NotImplementedError is rescued alongside StandardError because it descends
    # from ScriptError: an authority that implements only #search raises rather
    # than returning nothing when asked for every term.
    def terms_for(entry)
      return unless entry.stored_locally? || entry.origin == :file

      Qa::Authorities::Local.subauthority_for(entry.source_key).all
    rescue StandardError, NotImplementedError => e
      Rails.logger.warn("Unable to list terms for #{entry.source_key}: #{e.message}")
      nil
    end

    def file_based_names
      Qa::Authorities::Local.names
    rescue Qa::ConfigDirectoryNotFound => e
      Rails.logger.warn("Unable to list file-based local authorities: #{e.message}")
      []
    end

    private

    def remote_entry(provider, subauthority, configured)
      Entry.new(source_key: [provider, subauthority].compact.join('/'),
                # Names the vocabulary, not the key: titleizing `loc/iso639-1`
                # gives "Loc/Iso639 1", and the service has its own column.
                label: remote_vocabulary_label(subauthority) || provider_label(provider),
                origin: :remote,
                provider: provider,
                configured: configured)
    end

    def database_entry(vocabulary, totals)
      Entry.new(source_key: vocabulary.name,
                label: vocabulary.display_label,
                origin: cached_vocabulary?(vocabulary.name) ? :cached : :database,
                description: vocabulary.description,
                term_count: totals.fetch(vocabulary.id, 0),
                vocabulary: vocabulary,
                import_task: import_task_for(vocabulary.name))
    end

    # Local authorities qa knows about that have neither a row in this tenant nor a
    # yaml file, so a manager can see the vocabulary exists and what populates it.
    # mesh is the case in hand: registered at boot, filled by a rake task.
    def unimported_local
      accounted_for = Qa::LocalAuthority.pluck(:name).map(&:to_s) + file_based_names

      (registered_local_names - accounted_for).map do |name|
        Entry.new(source_key: name,
                  label: provider_label(name),
                  origin: cached_vocabulary?(name) ? :cached : :database,
                  term_count: 0,
                  import_task: import_task_for(name))
      end
    end

    def registered_local_names
      Qa::Authorities::Local.registry.keys.map(&:to_s)
    rescue StandardError => e
      Rails.logger.warn("Unable to list registered local authorities: #{e.message}")
      []
    end

    # Whether a locally-stored vocabulary holds a copy of an external one rather than
    # terms this tenant owns.
    #
    # The authority answers for itself: Qa::Authorities::Mesh reports
    # locally_owned? false because a MeSH import replaces all of its rows. An
    # authority that does not answer is assumed to be owned here, so a vocabulary is
    # only ever marked read-only deliberately.
    def cached_vocabulary?(name)
      authority = Qa::Authorities::Local.subauthority_for(name)
      return false unless authority.respond_to?(:locally_owned?)

      !authority.locally_owned?
    rescue StandardError => e
      Rails.logger.debug { "Unable to resolve #{name} while checking ownership: #{e.message}" }
      false
    end

    IMPORT_TASKS = { 'mesh' => 'mesh:import_tenant' }.freeze

    def import_task_for(name)
      IMPORT_TASKS[name]
    end

    def remote_vocabulary_label(vocabulary)
      return if vocabulary.blank?

      Qa::AuthorityRegistry.display_name(vocabulary)
    end

    # Locale-driven rather than from the registry: what to call a service in this
    # dashboard is presentation, and translatable.
    def provider_label(provider)
      I18n.t("hyku.admin.controlled_vocabulary.providers.#{provider}", default: provider.titleize)
    end

    # nil when an authority needs no credentials, so only the ones that do get
    # flagged.
    #
    # Read from this tenant's settings rather than from the authority class:
    # Qa::Authorities::Geonames.username is a class_attribute, so it holds whichever
    # tenant configured Hyrax most recently in this process, not the one being
    # viewed.
    def remote_configured?(provider)
      settings = Site.account&.settings
      return if settings.blank?

      case provider
      when 'discogs' then settings['discogs_user_token'].present?
      when 'geonames' then settings['geonames_username'].present?
      end
    rescue StandardError => e
      Rails.logger.warn("Unable to check configuration for #{provider}: #{e.message}")
      nil
    end

    # nil rather than 0 on failure, so the view can say "unknown" instead of
    # claiming an empty vocabulary.
    def file_term_count(name)
      Qa::Authorities::Local.subauthority_for(name).all.size
    rescue StandardError => e
      Rails.logger.warn("Unable to count terms for #{name}: #{e.message}")
      nil
    end
  end
end
# rubocop:enable Metrics/ClassLength
