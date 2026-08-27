# frozen_string_literal: true

# Shared by the deposit form (through `Hyrax::FormHelperBehavior`) and the
# indexer, so the two cannot disagree about which authority backs a property.
#
# This class stays in Hyku even after the indexing hook moves upstream: it reads
# Hyku's own controlled_vocab_mappings and Qa::LocalAuthority rows, which Hyrax
# has no knowledge of. It is what Hyku will register as the label-resolution
# service Hyrax calls, so treat its public methods as that seam and keep them
# stable.
class ControlledVocabularyLabels
  class << self
    # Existence, rather than m3's `"null"` sentinel, is what decides whether a
    # property is controlled: a profile is editable data, so `sources` can hold a
    # typo or a since-deleted vocabulary just as easily, and all of them mean the
    # same thing.
    def known_source?(source)
      name = source.to_s.strip
      return false if name.blank?
      return true if Hyrax::ControlledVocabularies.remote_authorities.key?(name)

      resolvable?(name)
    end

    # Resolved against the given schema_version rather than the newest profile: a
    # work pinned to an older profile has to be read with the sources that profile
    # declared.
    def source_for(property, schema_version: nil)
      if Hyrax.config.flexible?
        flexible_source_for(property, schema_version)
      else
        Hyrax::ControlledVocabularies.controlled_vocab_mappings[property.to_s]
      end
    end

    # Every controlled property for one model, as attribute name => authority
    # name, so an indexer resolves the profile once per document.
    #
    # Read through the schema loader, not the profile hash, and keyed by model:
    # two entries can describe the same attribute for different classes, as
    # `oer_resource_type` (`name: resource_type`, OerResource only, cites
    # oer_types) does against `resource_type` (cites resource_types). Only the
    # loader applies `available_on` and collapses `name:`.
    def sources_for(schema_version: nil, model: nil, contexts: nil)
      return static_sources unless Hyrax.config.flexible?
      return {} if model.blank?

      configs_for(model, schema_version, contexts).each_with_object({}) do |(name, config), sources|
        source = source_from_config(config)
        sources[name.to_s] = source if source
      end
    end

    # One entry per value, in the order given: the term's label, or the value
    # itself when the authority does not know it.
    #
    # Positional because the renderer pairs values to labels by index, so an
    # unresolved value has to hold its place — never compact this.
    def labels_for(source, values)
      values = Array.wrap(values)
      return values if source.blank? || values.empty?

      map = label_map(source)
      return values if map.blank?

      values.map { |value| map[value.to_s].presence || value }
    end

    # Remote authorities (LOC, Getty, FAST) are excluded deliberately: resolving
    # one means a network call per value, which has no place in indexing.
    def resolvable?(source)
      name = source.to_s
      return false if name.blank?
      return false if Hyrax::ControlledVocabularies.remote_authorities.key?(name)

      Qa::LocalAuthority.exists?(name:) || file_based?(name)
    end

    # Clears the current request's memo. Rarely needed in the app, where the store
    # is already per request; specs use it to isolate examples.
    def reset!
      RequestStore.store.delete(:controlled_vocabulary_label_maps)
    end

    private

    def static_sources
      Hyrax::ControlledVocabularies.controlled_vocab_mappings.dup
    end

    def flexible_source_for(property, schema_version)
      config = properties_for(schema_version)[property.to_s]
      source_from_config(config)
    end

    def configs_for(model, schema_version, contexts)
      Hyrax::Schema.m3_schema_loader.raw_attribute_configs(
        schema: model.to_s, version: schema_version, contexts:
      )
    rescue StandardError => e
      # A model the profile does not describe, or no profile yet: nothing to label.
      Rails.logger.debug { "No controlled vocabulary configs for #{model}: #{e.message}" }
      {}
    end

    # The first usable source wins, matching how the form picks which authority to
    # offer when a property lists several.
    def source_from_config(config)
      return unless config.is_a?(Hash)

      # Not `config.dig`: a profile is editable data, and a scalar here raises
      # TypeError mid-indexing.
      controlled = config['controlled_values']
      return unless controlled.is_a?(Hash)

      Array(controlled['sources'])
        .map { |source| source.to_s.strip }
        .find { |source| known_source?(source) }
    end

    # Mirrors `Hyrax::M3SchemaLoader#resolve_schema`, so a resource is read with
    # the profile its `schema_version` names and falls back the same way when that
    # row is gone.
    def properties_for(schema_version)
      schema = Hyrax::FlexibleSchema.find_by(id: schema_version) ||
               Hyrax::FlexibleSchema.order(:created_at).last
      schema&.profile&.fetch('properties', nil) || {}
    rescue ActiveRecord::StatementInvalid
      # No profile table yet (early boot, a fresh database).
      {}
    end

    # Held for the request only: staff edit terms while the app runs, and a memo
    # outliving the request would keep serving the old ones.
    def label_map(source)
      store = RequestStore.store[:controlled_vocabulary_label_maps] ||= {}
      return store[source] if store.key?(source)

      store[source] = build_label_map(source)
    end

    # One map for the whole authority rather than a `find` per value:
    # `Qa::Authorities::Local::FileBasedAuthority#find` re-reads and re-parses its
    # yaml on every call.
    def build_label_map(source)
      return {} unless resolvable?(source)

      Qa::Authorities::Local.subauthority_for(source.to_s).all.each_with_object({}) do |term, map|
        term = term.with_indifferent_access
        id = term[:id].to_s
        next if id.blank?

        # The two qa backends disagree: `all` normalizes to `label`, while a
        # table-backed authority can emit only `term`.
        map[id] = term[:label].presence || term[:term]
      end
    rescue StandardError => e
      # A missing authority must not fail an indexing run; the ids index as-is.
      Rails.logger.warn("Unable to load labels for controlled vocabulary #{source}: #{e.message}")
      {}
    end

    # Rescued because qa raises when a deployment has no config/authorities at
    # all — no yaml vocabularies to match, not a broken install.
    def file_based?(name)
      Qa::Authorities::Local.names.include?(name)
    rescue StandardError => e
      Rails.logger.debug { "Unable to list file-based local authorities: #{e.message}" }
      false
    end
  end
end
