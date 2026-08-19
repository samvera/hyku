# frozen_string_literal: true

# Assembles every authority a metadata profile can cite into one list, so staff
# can see what is available to put in `controlled_values.sources` without reading
# the code.
#
# Three origins:
#   :database — rows in this tenant, whether staff created them or a seed did
#   :file     — config/authorities/*.yml, deployment-wide
#   :remote   — external services (LOC, Getty, FAST), deployment-wide
#
# Only :database rows are editable, and only once the row exists — see Entry.
#
# TODO: over the ClassLength limit while the three assemblers live here. Extract
# Entry, or one assembler per origin, once term editing settles the shape.
# rubocop:disable Metrics/ClassLength
class ControlledVocabularyCatalog
  # Authorities registered as remote whose url actually points at a local table.
  # `mesh` is the case in hand: it is table-backed and populated by the separate
  # mesh:import_tenant task, so it belongs with the local vocabularies.
  LOCAL_URL_PREFIX = '/authorities/search/local/'

  ORIGIN_ORDER = { database: 0, file: 1, remote: 2 }.freeze

  # titleize mangles these, and an acronym expanded wrongly is worse than none.
  REMOTE_VOCABULARY_LABELS = {
    'aat' => 'Art & Architecture Thesaurus',
    'tgn' => 'Thesaurus of Geographic Names',
    'ulan' => 'Union List of Artist Names',
    'iso639-1' => 'ISO 639-1 Languages',
    'iso639-2' => 'ISO 639-2 Languages',
    'genre_forms' => 'Genre/Form Terms'
  }.freeze

  Entry = Struct.new(:source_key, :label, :origin, :description, :term_count,
                     :vocabulary, :provider, :configured, :import_task,
                     keyword_init: true) do
    # A registered local authority can have no row yet — mesh before its import —
    # so :database alone does not mean there is anything to edit.
    def editable?
      vocabulary.present?
    end

    def local?
      origin == :database
    end

    # File-based vocabularies are worth opening even though they cannot be edited.
    # Remote services are not enumerable, so they are not.
    def viewable?
      editable? || origin == :file
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

    # Term counts are unknowable without querying the service, so they stay nil.
    def remote
      remote_authorities.filter_map do |source_key, config|
        next if local_url?(config[:url])

        provider, vocabulary = source_key.split('/', 2)

        Entry.new(source_key: source_key,
                  # Names the vocabulary, not the key: titleizing `loc/iso639-1`
                  # gives "Loc/Iso639 1", and the service has its own column.
                  label: remote_vocabulary_label(vocabulary) || provider_label(provider),
                  origin: :remote,
                  provider: provider,
                  configured: remote_configured?(provider))
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
      return unless entry.local? || entry.origin == :file

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

    def remote_authorities
      Hyrax::ControlledVocabularies.remote_authorities
    end

    def database_entry(vocabulary, totals)
      Entry.new(source_key: vocabulary.name,
                label: vocabulary.display_label,
                origin: :database,
                description: vocabulary.description,
                term_count: totals.fetch(vocabulary.id, 0),
                vocabulary: vocabulary,
                import_task: import_task_for(vocabulary.name))
    end

    # Registered local authorities with no row in this tenant yet, so a manager can
    # see the vocabulary exists and what it takes to populate it.
    def unimported_local
      existing = Qa::LocalAuthority.pluck(:name).map(&:to_s)

      remote_authorities.filter_map do |source_key, config|
        next unless local_url?(config[:url])
        next if existing.include?(source_key)

        Entry.new(source_key: source_key,
                  label: provider_label(source_key),
                  origin: :database,
                  term_count: 0,
                  import_task: import_task_for(source_key))
      end
    end

    def local_url?(url)
      url.to_s.start_with?(LOCAL_URL_PREFIX)
    end

    IMPORT_TASKS = { 'mesh' => 'mesh:import_tenant' }.freeze

    def import_task_for(name)
      IMPORT_TASKS[name]
    end

    def remote_vocabulary_label(vocabulary)
      return if vocabulary.blank?

      REMOTE_VOCABULARY_LABELS.fetch(vocabulary) { vocabulary.titleize }
    end

    def provider_label(provider)
      I18n.t("hyku.admin.controlled_vocabulary.providers.#{provider}", default: provider.titleize)
    end

    # nil when an authority needs no credentials, so only the ones that do get
    # flagged. Mirrors the checks the form helper already makes before rendering.
    def remote_configured?(provider)
      case provider
      when 'discogs' then Site.account.respond_to?(:discogs_user_token) && Site.account.discogs_user_token.present?
      when 'geonames' then Qa::Authorities::Geonames.username.present?
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
