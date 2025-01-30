# frozen_string_literal: true

# OVERRIDE BULKRAX 8.1.0 to include oer specific methods and model level required fields checking
module Bulkrax
  module CsvParserDecorator
    include OerCsvParser
  end
end

Bulkrax::CsvParser.prepend(Bulkrax::CsvParserDecorator)
