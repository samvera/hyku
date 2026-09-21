# frozen_string_literal: true

module Hyrax
  # Which authority backs a property. The deposit form needs this to build a
  # field's options before any value exists, which is a different question from
  # resolving a stored id to its label — that is
  # `Hyrax.config.controlled_vocabulary_label_service`.
  module ControlledVocabularySourceHelper
    # The authority name backing +property_name+, or nil when the property isn't
    # controlled. Public because callers that only need to label a stored value
    # want the source without building the whole option list.
    #
    # Resolved against the given schema_version rather than the newest profile: a
    # work pinned to an older profile has to be read with the sources that
    # profile declared.
    def controlled_vocabulary_source_for(property_name, schema_version: nil, model: nil)
      return flexible_vocabulary_source_for(property_name, schema_version) if Hyrax.config.flexible?

      schema_vocabulary_source_for(property_name, model) ||
        controlled_vocabulary_mapping_for(property_name)
    end

    private

    # The yaml schemas declare their own authorities, and a model's own schema
    # is what distinguishes them: an OER work's resource_type cites oer_types
    # where every other work type cites resource_types. Without a model there is
    # no way to tell those apart, so the caller falls back to the static map.
    def schema_vocabulary_source_for(property_name, model)
      return if model.blank?

      Hyrax::SimpleSchemaLoader.new
                               .authority_rules_for(schema: model)[property_name.to_sym]
    rescue StandardError => e
      Rails.logger.debug { "No yaml schema authority for #{model}##{property_name}: #{e.message}" }
      nil
    end

    def flexible_vocabulary_source_for(property_name, schema_version)
      config = profile_properties_for(schema_version)[property_name.to_s]
      return unless config.is_a?(Hash)

      # Not `config.dig`: a profile is editable data, and a scalar here raises
      # TypeError mid-request.
      controlled = config['controlled_values']
      return unless controlled.is_a?(Hash)

      # The first usable source wins, matching how the form picks which authority
      # to offer when a property lists several.
      Array(controlled['sources'])
        .map { |source| source.to_s.strip }
        .find { |source| known_vocabulary_source?(source) }
    end

    # Existence, rather than m3's `"null"` sentinel, is what decides whether a
    # property is controlled: a profile is editable data, so `sources` can hold a
    # typo or a since-deleted vocabulary just as easily, and all of them mean the
    # same thing.
    def known_vocabulary_source?(source)
      name = source.to_s.strip
      return false if name.blank?
      return true if Hyrax::ControlledVocabularies.remote_authorities.key?(name)

      Hyrax.config.controlled_vocabulary_label_service.resolvable?(name)
    end

    # Mirrors `Hyrax::M3SchemaLoader#resolve_schema`, so a resource is read with
    # the profile its `schema_version` names and falls back the same way when
    # that row is gone.
    def profile_properties_for(schema_version)
      schema = Hyrax::FlexibleSchema.find_by(id: schema_version) ||
               Hyrax::FlexibleSchema.order(:created_at).last
      schema&.profile&.fetch('properties', nil) || {}
    rescue ActiveRecord::StatementInvalid
      # No profile table yet (early boot, a fresh database).
      {}
    end

    # Maps property names to vocabulary keys when flexible metadata is off and
    # the yaml schema does not declare one.
    # Hyku: config/initializers/hyrax_controlled_vocabularies.rb
    def controlled_vocabulary_mapping_for(property_name)
      Hyrax::ControlledVocabularies.controlled_vocab_mappings[property_name.to_s]
    end
  end
end
