# frozen_string_literal: true

module Importer
  # Import a csv file with one work per row. The first row of the csv should be a
  # header row. The model for each row can either be specified in a column called
  # 'type' or globally by passing the model attribute
  class CSVImporter
    # @param [String] metadata_file path to CSV file
    # @param [String] files_directory path, passed to factory constructor
    # @param [#to_s, Class] model if Class, the factory class to be invoked per row.
    # Otherwise, the stringable first (Xxx) portion of an "XxxFactory" constant.
    def initialize(metadata_file, files_directory, model = nil)
      @metadata_file = metadata_file
      @files_directory = files_directory
      @model = model
    end

    # @return [Integer] count of objects created
    def import_all
      count = 0
      parser.each do |attributes|
        create_fedora_objects(attributes)
        count += 1
      end
      count
    end

    private

      def parser
        CSVParser.new(@metadata_file)
      end

      # @return [Class] the model class to be used
      def factory_class(model)
        return model if model.is_a?(Class)
        if model.empty?
          warn 'ERROR: No model was specified'
          exit(1) # rubocop:disable Rails/Exit
        end
        return Factory.for(model.to_s) if model.respond_to?(:to_s)
        raise "Unrecognized model type: #{model.class}"
      end

      # Build a factory to create the objects in fedora.
      # @param [Hash<Symbol => String>] attributes
      # @option attributes [String] :type overrides model for a single object
      # @note remaining attributes are passed to factory constructor
      def create_fedora_objects(attributes)
        factory_class(attributes.delete(:type) || @model).new(attributes, @files_directory).run
      end
  end
end
