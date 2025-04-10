# frozen_string_literal: true

FactoryBot.define do
  factory :bulkrax_oer_csv_entry, class: 'Bulkrax::OerCsvEntry' do
    identifier { 'MyString' }
    type { 'Bulkrax::OerCsvEntry' }
    importerexporter { FactoryBot.build(:bulkrax_importer) }
    raw_metadata { 'MyText' }
    parsed_metadata { 'MyText' }
  end
end
