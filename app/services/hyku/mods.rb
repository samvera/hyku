# frozen_string_literal: true

module Hyku
  module Mods
    MAPPING_KEY = 'mods_oai_pmh'
    SCHEMA_PATH = Rails.root.join('config', 'schemas', 'mods', 'mods-3-7.xsd')

    # @return [Nokogiri::XML::Schema] MODS 3.7, with its imports read from beside it
    def self.schema
      @schema ||= File.open(SCHEMA_PATH) { |file| Nokogiri::XML::Schema(file) }
    end
  end
end
