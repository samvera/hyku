# frozen_string_literal: true

module Bulkrax
  class OerCsvParser < CsvParser
    def entry_class
      Bulkrax::OerCsvEntry
    end
  end
end
