# frozen_string_literal: true

module Bulkrax
  class EtdCsvParser < CsvParser
    def entry_class
      Bulkrax::EtdCsvEntry
    end
  end
end
