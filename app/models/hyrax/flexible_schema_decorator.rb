# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0
#   - add FlexibleSchema.multiple_values?, the loader's rule for whether a profile property holds many values
#   - add FlexibleSchema.profile_for, a profile version memoized per request in Hyrax::Current
#   Both are for Hyku::CollectionProfileReaders.
# TEMPORARY: re-evaluate and remove when samvera/hyrax#7732 is in the bundled Hyrax
module Hyrax
  module FlexibleSchemaDecorator
    extend ActiveSupport::Concern

    class_methods do
      def multiple_values?(config)
        return config['data_type'] == 'array' if config.key?('data_type')
        return config['multi_value'] if config.key?('multi_value')

        if (card = config['cardinality'])
          max = card['maximum']
          return max.nil? || max.to_i > 1
        end

        false
      end

      def profile_for(version)
        return current_version if version.blank? || version.to_s == current_schema_id.to_s

        Hyrax::Current.flexible_schema_profiles ||= {}
        Hyrax::Current.flexible_schema_profiles[version.to_s] ||= find_by(id: version)&.profile || current_version
      end
    end
  end
end

Hyrax::Current.attribute :flexible_schema_profiles unless Hyrax::Current.method_defined?(:flexible_schema_profiles)
Hyrax::FlexibleSchema.include(Hyrax::FlexibleSchemaDecorator)
