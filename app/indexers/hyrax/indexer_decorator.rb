# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to index a controlled property's term labels alongside
# the stored ids, as `<index_key>_label`. The ids are left in place: they are the
# link target for a URI-valued authority and what OAI harvests.
#
# TODO: TEMPORARY. Delete this file and its prepend in
# config/initializers/hyrax.rb once label indexing lands in Hyrax's own
# `Hyrax::Indexer#define_solr_method`. Upstream needs the label resolution to be
# injectable (a service on Hyrax.config defaulting to a no-op), since Hyrax
# cannot depend on Hyku's ControlledVocabularyLabels. Keep the indexing specs:
# they should pass unchanged against the upstream implementation.
#
# `define_solr_method` is re-declared in full rather than wrapped because the
# `to_solr` it defines closes over `schema_name` and `index_loader`, leaving no
# seam around the rules loop. Everything below mirrors upstream except the lines
# marked OVERRIDE, so re-sync when Hyrax changes this method.
#
# The prepend has to run before any indexer class body evaluates
# `include Hyrax::Indexer(...)`, which builds its `to_solr` immediately — hence an
# initializer rather than autoloading.
module Hyrax
  module IndexerDecorator
    def define_solr_method(schema_name:, index_loader:) # rubocop:disable Metrics/MethodLength
      define_method :to_solr do |*args|
        super(*args).tap do |document|
          schema_args = if index_loader.is_a?(Hyrax::M3SchemaLoader)
                          document['schema_version_ssi'] = resource.schema_version
                          document['contexts_ssim'] = resource.contexts
                          { schema: resource.class.name, version: resource.schema_version, contexts: resource.contexts }
                        else
                          { schema: schema_name }
                        end
          rules = @rules || index_loader.index_rules_for(**schema_args)

          # OVERRIDE: once per document, not once per property.
          sources = Hyrax::IndexerDecorator.controlled_sources(resource)

          rules.each do |index_key, method|
            value = resource.try(method)
            document[index_key] = value

            # OVERRIDE: add the label companion for a controlled property.
            Hyrax::IndexerDecorator.add_label(document, index_key, sources[method.to_s], value)
          end
        end
      end
    end

    def self.add_label(document, index_key, source, value)
      return if source.blank?

      label_key = label_key_for(index_key)
      return if label_key.blank?

      labels = ControlledVocabularyLabels.labels_for(source, value)
      document[label_key] = labels if labels.present?
    end

    # `resource_type_tesim` -> `resource_type_label_tesim`. The suffix has to stay
    # last: Solr resolves these through dynamic field rules keyed on the suffix, so
    # `resource_type_sim_label` is not a field and indexing it fails the whole
    # document with a 400.
    def self.label_key_for(index_key)
      key = index_key.to_s
      base, _, suffix = key.rpartition('_')
      return if base.blank? || suffix.blank?

      "#{base}_label_#{suffix}"
    end

    # Keyed on the resource's own class as well as its schema version: the class is
    # what distinguishes two profile entries for the same attribute — see
    # ControlledVocabularyLabels.sources_for.
    def self.controlled_sources(resource)
      ControlledVocabularyLabels.sources_for(
        schema_version: resource.try(:schema_version),
        model: resource.class,
        contexts: resource.try(:contexts)
      )
    rescue StandardError => e
      # Never let label resolution break an indexing run; ids index as-is.
      Rails.logger.warn("Unable to resolve controlled vocabulary sources: #{e.message}")
      {}
    end
  end
end
