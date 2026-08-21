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

  # How many terms a page will list. A vocabulary can hold tens of thousands — the
  # MeSH release is around 30,000 — and rendering them all serves nobody. The view
  # compares this against the real count so a truncated list says so.
  TERM_LIMIT = 500

  Entry = Struct.new(:source_key, :label, :origin, :description, :term_count,
                     :vocabulary, :provider, :configured, :import_task,
                     keyword_init: true) do
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

    # A remote service is not enumerable, and an imported copy holds far too many
    # terms to page through.
    def listable?
      editable? || origin == :file
    end

    def downloadable?
      vocabulary.present? || origin == :file
    end

    # nil means the authority needs no credentials, so only a known-missing one is
    # reported unconfigured.
    def configured?
      configured != false
    end

    def awaiting_import?
      import_task.present? && term_count.to_i.zero?
    end

    # Where the vocabulary comes from, for display: the service for a remote
    # authority, otherwise the origin.
    def source_label
      if provider
        I18n.t("hyku.admin.controlled_vocabulary.providers.#{provider}", default: provider.titleize)
      else
        I18n.t("hyku.admin.controlled_vocabulary.origins.#{origin}")
      end
    end
  end

  class << self
    # Remote entries sort by provider so services stay together: a bare "Corporate"
    # or "Master" only makes sense next to the service it belongs to.
    #
    # @return [Array<Entry>]
    def all
      # One read, shared: two reads that disagreed would emit the same source key
      # under two origins.
      yaml_names = file_based_names

      (database(yaml_names) + file_based(yaml_names) + remote).sort_by do |entry|
        [ORIGIN_ORDER.fetch(entry.origin, 9),
         entry.provider.to_s.downcase,
         entry.label.to_s.downcase]
      end
    end

    def database(yaml_names = file_based_names)
      vocabularies = Qa::LocalAuthority.ordered.to_a
      # One grouped count rather than one per vocabulary.
      totals = Qa::LocalAuthorityEntry.where(local_authority: vocabularies).group(:local_authority_id).count

      entries = vocabularies.map { |vocabulary| database_entry(vocabulary, totals) }

      (entries + unimported_local(yaml_names)).sort_by { |e| e.label.to_s.downcase }
    end

    # Excludes names already backed by a database row: the row is what staff see
    # and edit, so listing both would imply two separate vocabularies.
    def file_based(yaml_names = file_based_names)
      claimed = Qa::LocalAuthority.pluck(:name).map(&:to_s)

      (yaml_names - claimed).map do |name|
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
      key = source_key.to_s

      # After a direct miss, so a vocabulary named with the alternate spelling still
      # answers for itself.
      find_by_source_key(key) ||
        aliases_for(key).lazy.filter_map { |alt| find_by_source_key(alt) }.first ||
        raise(ActiveRecord::RecordNotFound, "No controlled vocabulary named #{key}")
    end

    # Read from the entries table rather than through the authority, whose classes do
    # not agree: Mesh implements only #search, so #all raises, and LocalVocabulary
    # silently caps at 1,000.
    #
    # @return [Array<Hash>, nil] each with id, label, and active; nil when the terms
    #   cannot be listed at all
    def terms_for(entry)
      return file_terms(entry.source_key) if entry.origin == :file
      # Imported copies are not listed at all: a MeSH release runs to about 30,000
      # terms, and a page of the first few hundred tells a reader nothing useful.
      return unless entry.origin == :database
      return [] if entry.vocabulary.nil?

      entry.vocabulary.local_authority_entries.ordered.limit(TERM_LIMIT).map do |term|
        { 'id' => term.uri, 'label' => term.label, 'active' => term.active }
      end
    end

    # A yaml vocabulary has no rows, so its terms come from the authority.
    def file_terms(name)
      Qa::Authorities::Local.subauthority_for(name).all.first(TERM_LIMIT).map do |term|
        term = term.with_indifferent_access
        { 'id' => term[:id], 'label' => term[:label], 'active' => term[:active] }
      end
    rescue StandardError, NotImplementedError => e
      Rails.logger.warn("Unable to list terms for #{name}: #{e.message}")
      nil
    end

    def file_based_names
      Qa::Authorities::Local.names
    rescue Qa::ConfigDirectoryNotFound => e
      Rails.logger.warn("Unable to list file-based local authorities: #{e.message}")
      []
    end

    # Two keys on one url in remote_authorities are the same vocabulary
    # (`loc/genre_forms`, `loc/genreForms`), so an alias added there needs nothing
    # here. Emitting every spelling from .remote would list one vocabulary twice.
    def aliases_for(key)
      authorities = Hyrax::ControlledVocabularies.remote_authorities
      url = authorities.dig(key.to_s, :url)
      return [] if url.blank?

      authorities.each_with_object([]) do |(sibling, config), found|
        found << sibling if sibling != key.to_s && config[:url] == url
      end
    end

    private

    # Database rows first: the other origins walk every qa authority and parse every
    # yaml, which a hit here avoids.
    def find_by_source_key(key)
      return if key.blank?

      yaml_names = file_based_names

      database(yaml_names).detect { |entry| entry.source_key == key } ||
        (file_based(yaml_names) + remote).detect { |entry| entry.source_key == key }
    end

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
                # A staff label wins, then the locale, then a titleized name. Skipping
                # the locale would rename MeSH to "Mesh" once it has a row.
                label: vocabulary.label.presence || provider_label(vocabulary.name),
                origin: cached_vocabulary?(vocabulary.name) ? :cached : :database,
                description: vocabulary.description,
                term_count: totals.fetch(vocabulary.id, 0),
                vocabulary: vocabulary,
                import_task: import_task_for(vocabulary.name))
    end

    # Local authorities qa knows about that have neither a row in this tenant nor a
    # yaml file, so a manager can see the vocabulary exists and what populates it.
    # mesh is the case in hand: registered at boot, filled by a rake task.
    def unimported_local(yaml_names = file_based_names)
      accounted_for = Qa::LocalAuthority.pluck(:name).map(&:to_s) + yaml_names

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

    # Listed rather than matched on a prefix: `loc` would find `locale_name` and
    # report the Library of Congress unconfigured.
    PROVIDER_SETTINGS = { 'discogs' => :discogs_user_token, 'geonames' => :geonames_username }.freeze

    # nil for an authority that needs no credentials, so only the ones that do get
    # flagged.
    #
    # Read through the account's accessors, not Site.account.settings: the readers
    # apply the HYKU_/HYRAX_ environment fallbacks, so the raw hash reports a
    # credential missing when the environment supplies it.
    def remote_configured?(provider)
      setting = PROVIDER_SETTINGS[provider]
      return if setting.nil?

      account = Site.account
      return false if account.nil?

      account.public_send(setting).present?
    rescue StandardError => e
      Rails.logger.warn("Unable to check configuration for #{provider}: #{e.message}")
      # false, not nil: nil reads as configured, sending staff to debug a form that
      # was never going to work.
      false
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
