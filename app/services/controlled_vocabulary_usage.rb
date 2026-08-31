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

    # Form partials that hardcode an authority the profile and the generic mapping
    # do not name: the OER form fills resource_type from oer_types, and based_near
    # autocompletes against geonames. A nil class list means every model defining
    # the property.
    PARTIAL_SOURCES = {
      'oer_types' => { property: 'resource_type', classes: ['OerResource'] },
      'geonames' => { property: 'based_near', classes: nil }
    }.freeze

    def from_profile(profile, key)
      properties = profile['properties'] || {}
      # Every spelling, because the dashboard resolves a legacy key to the entry
      # keyed canonically and then asks for that key's usage.
      keys = [key] + ControlledVocabularyCatalog.aliases_for(key)

      declared = properties.filter_map do |name, config|
        next unless config.is_a?(Hash) && cites?(config, keys)

        Property.new(name: name, work_types: work_types(config))
      end

      declared + profile_partial_properties(profile, key, declared)
    end

    # A partial that hardcodes its authority leaves the profile with nothing to
    # declare — based_near carries `sources: ["null"]` while its form partial
    # autocompletes against geonames. The property is still controlled, and the
    # profile is still where its work types come from.
    def profile_partial_properties(profile, key, declared)
      config = PARTIAL_SOURCES[key]
      return [] if config.nil?
      return [] if declared.any? { |property| property.name == config[:property] }

      property_config = (profile['properties'] || {})[config[:property]]
      return [] unless property_config.is_a?(Hash)

      types = work_types(property_config)
      types = types.select { |type| config[:classes].include?(type.name) } if config[:classes]
      return [] if types.empty?

      [Property.new(name: config[:property], work_types: types)]
    end

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

        WorkType.new(name: klass.name, label: class_label(klass.name))
      end
    end

    # Valkyrie classes only: the registry also lists each type's ActiveFedora
    # counterpart, which would double every work type shown.
    def model_classes
      (Hyrax::ModelRegistry.work_classes +
        Hyrax::ModelRegistry.collection_classes +
        Hyrax::ModelRegistry.file_set_classes).select { |klass| klass < Valkyrie::Resource }
    end

    # Sources are stripped because profiles have shipped them with stray whitespace;
    # the form helper reads them the same way.
    def cites?(config, keys)
      Array(config.dig('controlled_values', 'sources')).any? do |source|
        keys.include?(source.to_s.strip)
      end
    end

    def work_types(config)
      Array(config.dig('available_on', 'class')).map do |class_name|
        WorkType.new(name: class_name, label: class_label(class_name))
      end
    end

    # From the class name, not the profile's display_label: profiles have shipped
    # with labels like "pcdmcollection", and the class name is stable across
    # tenants. The Valkyrie suffix is an implementation detail staff never see.
    def class_label(class_name)
      I18n.t("hyku.admin.controlled_vocabulary.work_types.#{class_name.underscore}",
             default: class_name.demodulize.delete_suffix('Resource').titleize)
    end
  end
end
