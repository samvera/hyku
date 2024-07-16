# frozen_string_literal: true

RSpec.describe Bulkrax::CsvParserDecorator, type: :decorator, skip: 'TODO: We need to revisit this for Valkyrie' do
  subject(:csv_parser) do
    Bulkrax::CsvParser.new(
      instance_double(
        'Bulkrax::Importer', parser_klass: "Bulkrax::CsvParser",
                             only_updates: false,
                             file?: false,
                             parser_fields: {},
                             set_status_info: double('Bulkrax::Status'),
                             metadata_only?: true
      )
    )
  end

  # Pardon the verbosity but I wanted to emphasize which fields are currently required for each model
  let(:generic_work_record) do
    {
      model: 'GenericWork',
      title: 'Generic Work Title',
      creator: 'Smith, John',
      keyword: 'keyword',
      rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
      resource_type: 'Article',
      date_created: nil,
      audience: nil,
      education_level: nil,
      learning_resource_type: nil,
      discipline: nil,
      degree_name: nil,
      degree_level: nil,
      degree_discipline: nil,
      degree_grantor: nil
    }
  end
  let(:image_record) do
    {
      model: 'Image',
      title: 'Image Title',
      creator: 'Smith, John',
      keyword: 'keyword',
      rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
      resource_type: 'Article',
      date_created: nil,
      audience: nil,
      education_level: nil,
      learning_resource_type: nil,
      discipline: nil,
      degree_name: nil,
      degree_level: nil,
      degree_discipline: nil,
      degree_grantor: nil
    }
  end
  let(:oer_record) do
    {
      model: 'Oer',
      title: 'Oer Title',
      creator: 'Smith, John',
      keyword: nil,
      rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
      resource_type: 'Article',
      date_created: '2018-01-01',
      audience: 'Student',
      education_level: 'community college / lower division',
      learning_resource_type: 'Activity/lab',
      discipline: 'Languages - Spanish',
      degree_name: nil,
      degree_level: nil,
      degree_discipline: nil,
      degree_grantor: nil
    }
  end
  let(:etd_record) do
    {
      model: 'Etd',
      title: 'Etd Title',
      creator: 'Smith, John',
      keyword: 'keyword',
      rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
      resource_type: 'Article',
      date_created: '2018-01-01',
      audience: nil,
      education_level: nil,
      learning_resource_type: nil,
      discipline: nil,
      degree_name: 'Bachelor of Science',
      degree_level: 'Bachelors',
      degree_discipline: 'Languages - Spanish',
      degree_grantor: 'University of California, Los Angeles'
    }
  end
  let(:collection_record) do
    {
      model: 'Collection',
      title: 'Collection Title',
      creator: nil,
      keyword: nil,
      rights_statement: nil,
      resource_type: nil,
      date_created: nil,
      audience: nil,
      education_level: nil,
      learning_resource_type: nil,
      discipline: nil,
      degree_name: nil,
      degree_level: nil,
      degree_discipline: nil,
      degree_grantor: nil
    }
  end
  let(:file_set_record) do
    {
      model: 'FileSet',
      title: nil,
      creator: nil,
      keyword: nil,
      rights_statement: nil,
      resource_type: nil,
      date_created: nil,
      audience: nil,
      education_level: nil,
      learning_resource_type: nil,
      discipline: nil,
      degree_name: nil,
      degree_level: nil,
      degree_discipline: nil,
      degree_grantor: nil
    }
  end
  let(:records) do
    [generic_work_record, image_record, oer_record, etd_record, collection_record, file_set_record]
  end

  before do
    allow(subject).to receive(:records).and_return(records)
  end

  describe '#valid_import?' do
    context 'when all required fields are present' do
      it 'returns true' do
        expect(subject.valid_import?).to be true
      end
    end

    context 'when required fields are missing' do
      let(:generic_work_record_with_no_title_and_no_creator) { generic_work_record.merge(title: nil, creator: nil) }
      let(:collection_record_with_no_title) { collection_record.merge(title: nil) }
      let(:records) { [collection_record_with_no_title, generic_work_record_with_no_title_and_no_creator] }

      it 'returns false' do
        expect(subject.valid_import?).to be false
      end

      it 'rescues the error and calls set_status_info' do
        expect(subject).to receive(:set_status_info) do |e|
          expect(e).to be_a(StandardError)
          expect(e.message).to eq('Collection missing: title; GenericWork missing: title, creator')
        end

        subject.valid_import?
      end
    end

    context 'when the csv headers are in any case (capitalized or lowercased)' do
      let(:generic_work_record_with_capitalized_headers) do
        generic_work_record.transform_keys(&:to_s)
                           .transform_keys(&:capitalize)
      end
      let(:records) { [generic_work_record_with_capitalized_headers] }

      it 'still returns true' do
        expect(subject.valid_import?).to be true
      end
    end

    context 'when the csv header is the parser_mappings value' do
      let(:generic_work_record_with_type_instead_of_resource_type) do
        generic_work_record.transform_keys! { |key| key == :resource_type ? :type : key }
      end
      let(:records) { [generic_work_record_with_type_instead_of_resource_type] }

      it 'still returns true' do
        expect(subject.valid_import?).to be true
      end
    end

    context 'when the csv header is a sequential number' do
      let(:generic_work_record_with_sequential_fields) do
        generic_work_record.transform_keys! { |key| key == :resource_type ? :type_1 : key }
      end
      let(:records) { [generic_work_record_with_sequential_fields] }

      it 'still returns true' do
        expect(subject.valid_import?).to be true
      end
    end
  end
end
