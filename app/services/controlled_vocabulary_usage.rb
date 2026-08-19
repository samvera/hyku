# frozen_string_literal: true

# What a controlled vocabulary controls: the properties that cite it and the work
# types each property is available on, read from the tenant's current metadata
# profile, or from the static form mapping when flexible metadata is off.
# Configuration only, not a count over deposited works.
class ControlledVocabularyUsage
  Property = Struct.new(:name, :work_types, keyword_init: true)
  WorkType = Struct.new(:name, :label, keyword_init: true)

  class << self
    # @param source_key [String] the key a profile cites in controlled_values.sources
    # @return [Array<Property>, nil] nil when usage cannot be determined (flexible
    #   metadata on but no profile saved yet), which is not the same answer as []:
    #   an empty array means nothing cites the vocabulary.
    def citing(source_key)
      key = source_key.to_s

      properties = if Hyrax.config.flexible?
                     profile = Hyrax::FlexibleSchema.current_version
                     return if profile.nil?

                     from_profile(profile, key)
                   else
                     from_mappings(key)
                   end

      properties.sort_by(&:name)
    end

    private

    def from_profile(profile, key)
      properties = profile['properties'] || {}

      properties.filter_map do |name, config|
        next unless config.is_a?(Hash) && cites?(config, key)

        Property.new(name: name, work_types: work_types(profile, config))
      end
    end

    # Form partials that read an authority the generic mapping does not list: the
    # OER form fills resource_type from oer_types, and based_near autocompletes
    # against geonames. A nil class list means every model defining the property.
    PARTIAL_SOURCES = {
      'oer_types' => { property: 'resource_type', classes: ['OerResource'] },
      'geonames' => { property: 'based_near', classes: nil }
    }.freeze

    # Without flexible metadata there is no profile; which properties a vocabulary
    # controls comes from the static mapping the deposit form itself uses, and the
    # work types from which model classes define the property.
    def from_mappings(key)
      mapped = Hyrax::ControlledVocabularies.controlled_vocab_mappings.filter_map do |name, source|
        next unless source == key

        Property.new(name: name, work_types: model_work_types(name))
      end

      mapped + partial_properties(key)
    end

    def partial_properties(key)
      config = PARTIAL_SOURCES[key]
      return [] unless config

      work_types = model_work_types(config[:property])
      work_types = work_types.select { |work_type| config[:classes].include?(work_type.name) } if config[:classes]
      return [] if work_types.empty?

      [Property.new(name: config[:property], work_types: work_types)]
    end

    def model_work_types(name)
      model_classes.filter_map do |klass|
        next unless klass.fields.include?(name.to_sym)

        WorkType.new(name: klass.name, label: model_label(klass))
      end
    end

    # The Valkyrie suffix is an implementation detail; staff know these as work
    # types, matching what a profile-backed tenant sees.
    def model_label(klass)
      I18n.t("hyku.admin.controlled_vocabulary.work_types.#{klass.name.underscore}",
             default: klass.name.demodulize.delete_suffix('Resource').titleize)
    end

    # Valkyrie classes only: the registry also lists each type's ActiveFedora
    # counterpart, which would double every work type shown.
    def model_classes
      (Hyrax::ModelRegistry.work_classes +
        Hyrax::ModelRegistry.collection_classes +
        Hyrax::ModelRegistry.file_set_classes).select { |klass| klass < Valkyrie::Resource }
    end

    # Keys are stripped because profiles have shipped them with stray whitespace;
    # the form helper reads them the same way.
    def cites?(config, key)
      Array(config.dig('controlled_values', 'sources')).any? do |source|
        source.to_s.strip == key
      end
    end

    def work_types(profile, config)
      Array(config.dig('available_on', 'class')).map do |class_name|
        WorkType.new(name: class_name, label: work_type_label(profile, class_name))
      end
    end

    # Labels the shipped profile got wrong; profiles saved before the fix still
    # carry them, so they fall through to the locale instead of the profile.
    MISLABELED_CLASSES = ['pcdmcollection'].freeze

    def work_type_label(profile, class_name)
      label = profile.dig('classes', class_name, 'display_label').presence
      return label if label && MISLABELED_CLASSES.exclude?(label)

      I18n.t("hyku.admin.controlled_vocabulary.work_types.#{class_name.underscore}",
             default: label || class_name)
    end
  end
end
