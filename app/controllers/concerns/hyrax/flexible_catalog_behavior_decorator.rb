# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to show controlled-vocabulary labels in the catalog rather
# than the term ids works store.
#
# TODO: TEMPORARY. Remove once Hyrax treats a property's controlled_values as
# first-class in the catalog, rather than deriving every solr name from
# "#{itemprop}". See lib/hyrax_overrides/indexer_decorator.rb for the indexing half.
#
# Driven off the profile rather than a list of field names, so a property or
# vocabulary added to an m3 profile is covered without touching CatalogController.
#
# Everything here runs once per controller instantiation — so once per request —
# against a class-level config that persists between them, and upstream reapplies
# its own schema each time. Every change below therefore has to be safe to repeat.
#
# A property may declare `name:` to stand in for another on a different class, as
# oer_resource_type does for resource_type. The named attribute is what gets
# indexed, so it is the name every solr field here derives from, and the surrogate's
# own key never holds values.
module Hyrax
  module FlexibleCatalogBehaviorDecorator
    def load_flexible_schema
      super

      apply_controlled_vocabulary_labels!
    end

    private

    def apply_controlled_vocabulary_labels!
      hide_surrogate_facets!

      controlled_properties.each do |itemprop|
        show_labels_in_search_results!(itemprop)
        facet_on_labels!(itemprop)
      end
    end

    # Sources come from the profile being loaded, not
    # ControlledVocabularyLabels.source_for, which resolves against the newest
    # schema — during a load those are not always the same one.
    def controlled_properties
      profile_properties.filter_map do |itemprop, config|
        next unless config.is_a?(Hash)

        source = Array(config.dig('controlled_values', 'sources')).map { |s| s.to_s.strip }
                                                                  .find { |s| ControlledVocabularyLabels.known_source?(s) }
        next if source.blank?

        indexed_name_for(itemprop, config)
      end.uniq
    end

    # A malformed property config would otherwise raise here, taking down every
    # catalog page rather than the one property.
    def indexed_name_for(itemprop, config)
      return itemprop unless config.is_a?(Hash)

      config['name'].presence || itemprop
    end

    # OVERRIDE: upstream leaves the row reading the id field.
    def show_labels_in_search_results!(itemprop)
      field = index_field_for(itemprop)
      return if field.nil?

      field.values = ControlledVocabularyFieldValues.to_proc
    end

    # Mirrors how upstream resolves the row it registers (FlexibleCatalogBehavior
    # picks the first index_fields key starting with the property, falling back to
    # _tesim), so a property CatalogController declares under another suffix is
    # found here too rather than being left with neither labels nor a facet link.
    def index_field_for(itemprop)
      name = blacklight_config.index_fields.keys.detect { |key| key.start_with?(itemprop.to_s) }

      blacklight_config.index_fields[name || "#{itemprop}_tesim"]
    end

    # OVERRIDE: upstream facets and links on "#{itemprop}_sim", and re-adds that
    # facet on every pass — so this guards the add, which Blacklight raises on when
    # the key already exists.
    #
    # The id facet stays registered, only hidden. Blacklight resolves a filter and
    # facet_field_response against configured facets alone, so unregistering it
    # would drop every bookmarked "f[<prop>_sim][]" constraint silently and raise
    # for the themes that request that facet by name.
    def facet_on_labels!(itemprop)
      id_name = "#{itemprop}_sim"
      label_name = "#{itemprop}_label_sim"
      existing = blacklight_config.facet_fields[id_name]
      existing.show = false if existing

      unless blacklight_config.facet_fields.key?(label_name)
        return if existing.nil?

        blacklight_config.add_facet_field(label_name, **label_facet_options(existing))
      end

      field = index_field_for(itemprop)
      field.link_to_facet = label_name if field
    end

    # Carried over wholesale rather than by naming a few keys: a facet may be
    # declared with helper_method, sort or partial, and the label facet renders
    # the same way its id counterpart did.
    def label_facet_options(existing)
      existing.to_h
              .except(:field, :show)
              .merge(label: facet_label_for(existing))
    end

    # Resolved rather than copied: a facet declared without a label stores the
    # titleized solr key ("Keyword Sim"), which only stays hidden because
    # display_label finds the "…fields.facet.<key>" translation first — and the
    # renamed key has no such translation.
    def facet_label_for(existing)
      existing.display_label('facet')
    end

    # OVERRIDE: upstream registers a facet under the surrogate's own key, which
    # holds no values. Hidden rather than unregistered, for the same reason
    # facet_on_labels! keeps the id facet: an unconfigured facet makes Blacklight
    # drop a filter silently and raise from facet_field_response.
    def hide_surrogate_facets!
      profile_properties.each do |itemprop, config|
        next if indexed_name_for(itemprop, config).to_s == itemprop.to_s

        blacklight_config.facet_fields["#{itemprop}_sim"]&.show = false
      end
    end

    def profile_properties
      Hyrax::FlexibleSchema.order(:created_at).last&.profile&.fetch('properties', nil) || {}
    rescue ActiveRecord::StatementInvalid
      {}
    end
  end
end

Hyrax::FlexibleCatalogBehavior::ClassMethods.prepend(Hyrax::FlexibleCatalogBehaviorDecorator)
