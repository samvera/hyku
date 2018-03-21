require 'importer'

RSpec.describe Importer::CSVParser do
  let(:parser) { described_class.new(file) }
  let(:attributes) { parser.attributes }
  let(:file) { "#{fixture_path}/csv/gse_metadata.csv" }
  let(:first_record) { parser.first }

  context 'Importing just images' do
    it 'parses a record' do
      # Title must be singular
      expect(first_record[:title]).to eq ['Work in Progress - A Framework for Building Interactive Learning Modules']

      expect(first_record[:file]).to eq ['DalmonEtAl2011_Framework_Final.pdf']

      expect(first_record[:date_created]).to eq ['2011']

      expect(first_record[:contributor]).to eq [{ name: ["Dalmon, Danilo"] },
                                                { name: ["Brandao, Leonidas"] },
                                                { name: ["Brandao, Anarosa"] },
                                                { name: ["Isotani, Seiji"] }]
      expect(first_record.keys).to match_array %i[id type title description
                                                  subject resource_type contributor
                                                  date_created file]
    end
  end

  describe 'validating CSV headers' do
    subject { parser.send(:validate_headers, headers) }

    context 'with valid headers' do
      let(:headers) { %w[id title] }

      it { is_expected.to eq headers }
    end

    context 'with invalid headers' do
      let(:headers) { ['something bad', 'title'] }

      it 'raises an error' do
        expect { subject }.to raise_error 'Invalid headers: something bad'
      end
    end

    context 'with nil headers' do
      let(:headers) { ['title', nil] }

      it { is_expected.to eq headers }
    end

    # It doesn't expect a matching column for "resource_type"
    context 'with resource_type column' do
      let(:headers) { %w[resource_type title] }

      it { is_expected.to eq headers }
    end
  end

  describe "validate_header_pairs" do
    subject { parser.send(:validate_header_pairs, headers) }

    context 'with "*_type" columns' do
      let(:headers) { %w[rights_holder rights_holder_type rights_holder title note_type note] }

      it { is_expected.to be_nil }
    end

    # The CSV parser assumes that the *_type column comes just
    # before the column that contains the value for that local
    # authority.  If the columns aren't in the correct order,
    # raise an error.
    context 'with columns in the wrong order' do
      let(:headers) { %w[note note_type rights_holder_type rights_holder_type rights_holder title] }

      it 'raises an error' do
        expect { subject }.to raise_error "Invalid headers: 'note_type' column " \
          "must be immediately followed by 'note' column., Invalid headers: " \
          "'rights_holder_type' column must be immediately followed by " \
          "'rights_holder' column."
      end
    end
  end
end
