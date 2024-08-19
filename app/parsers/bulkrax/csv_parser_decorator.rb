# frozen_string_literal: true

# OVERRIDE BULKRAX 8.1.0 to include oer specific methods and model level required fields checking
module Bulkrax
  module CsvParserDecorator
    include OerCsvParser

    # TODO: We need to revisit this for Valkyrie
    #
    # def valid_import?
    #   missing_fields_by_model = records.each_with_object({}) do |record, hash|
    #     record.compact!
    #     record.transform_keys!(&:downcase).transform_keys!(&:to_sym)
    #     missing_fields = missing_fields_for(record)
    #     hash[record[:model]] = missing_fields if missing_fields.present?
    #   end

    #   raise_error_for_missing_fields(missing_fields_by_model) if missing_fields_by_model.keys.present?

    #   file_paths.is_a?(Array)
    # rescue StandardError => e
    #   set_status_info(e)
    #   false
    # end

    # private

    # def missing_fields_for(record)
    #   required_fields = determine_required_fields_for(record[:model])
    #   required_fields.select do |field|
    #     # checks the field itself
    #     # any parser_mappings fields terms from `config/initializers/bulkrax.rb`
    #     # or any keys that has sequential numbers like creator_1
    #     (record[field] ||
    #       mapped_from(field).map { |f| record[f] }.any? ||
    #       handle_keys_with_numbers(field, record)).blank?
    #   end
    # end

    # def determine_required_fields_for(model)
    #   # TODO: Revisit when Valkyrized as we can use Hyrax::ModelRegistry
    #   case model
    #   when 'Collection' then Hyrax::Forms::CollectionForm.required_fields
    #   when 'FileSet' then []
    #   else "Hyrax::#{model}Form".constantize.required_fields
    #   end
    # end

    # def mapped_from(field)
    #   Bulkrax.config.field_mappings[self.class.to_s][field.to_s]&.fetch(:from, [])&.map(&:to_sym)
    # end

    # def handle_keys_with_numbers(_field, record)
    #   keys_with_numbers = record.keys.select { |k| k.to_s.match(/(.+)_\d+/) }
    #   keys_with_numbers.each do |key|
    #     return record[key]
    #   end
    # end

    # def raise_error_for_missing_fields(missing_fields_by_model)
    #   error_alert = missing_fields_by_model.keys.map do |model|
    #     "#{model} missing: #{missing_fields_by_model[model].join(', ')}"
    #   end.join('; ')
    #   # example alert: 'Collection missing: title; GenericWork missing: title, creator'
    #   raise StandardError, error_alert
    # end
  end
end

Bulkrax::CsvParser.prepend(Bulkrax::CsvParserDecorator)
