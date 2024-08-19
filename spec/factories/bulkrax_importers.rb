# frozen_string_literal: true

FactoryBot.define do
  factory :bulkrax_importer_oer_csv, class: 'Bulkrax::Importer' do
    name { 'OER CSV Import' }
    admin_set_id { 'MyString' }
    user { FactoryBot.build(:user) }
    frequency { 'PT0S' }
    parser_klass { 'Bulkrax::CsvParser' }
    limit { 10 }
    parser_fields { { 'import_file_path' => 'spec/fixtures/csv/oer_with_simple_relationships.csv' } }
    field_mapping { {} }
  end

  factory :bulkrax_importer_oer_csv_complex, class: 'Bulkrax::Importer' do
    name { 'OER CSV Import' }
    admin_set_id { 'MyString' }
    user { FactoryBot.build(:user) }
    frequency { 'PT0S' }
    parser_klass { 'Bulkrax::CsvParser' }
    limit { 10 }
    parser_fields { { 'import_file_path' => 'spec/fixtures/csv/oer_with_complex_relationships.csv' } }
    field_mapping { {} }
  end
end
