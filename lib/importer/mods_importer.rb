# frozen_string_literal: true

require 'stanford'
module Importer
  class ModsImporter
    class_attribute :parser_class
    self.parser_class = Stanford::Importer::ModsParser

    def initialize(files_directory, metadata_directory = nil)
      @files_directory = files_directory
      @metadata_directory = metadata_directory
    end

    # @return [Fixnum] the count of imports
    def import_all
      count = 0
      Dir.glob("#{@metadata_directory}/**/*").each do |filename|
        next if File.directory?(filename)
        import(filename)
        count += 1
      end
      count
    end

    def import(file)
      Rails.logger.info "Importing: #{file}"
      parser = parser_class.new(file)
      create_fedora_objects(parser.model, parser.attributes)
    end

    # Select a factory to create the objects in fedora.
    # For example, if we are importing a MODS record for an
    # image, the ModsParser will return an Image model, so
    # we'll select the ImageFactory to create the fedora
    # objects.
    def create_fedora_objects(model, attributes)
      Factory.for(model.to_s).new(attributes, @files_directory, files(attributes)).run
    end

    # @param [Hash] attributes the attribuutes from the parser
    # @return [Array] a list of file names to import
    def files(attributes)
      attributes[:files]
    end
  end
end
