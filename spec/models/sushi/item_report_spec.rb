# frozen_string_literal:true

RSpec.describe Sushi::ItemReport do
  subject { described_class.new(params, created:, account:).as_json }

  let(:account) { double(Account, institution_name: 'Pitt', institution_id_data: {}, cname: 'pitt.hyku.test') }
  let(:created) { Time.zone.now }
  let(:required_parameters) do
    {
      begin_date: '2022-01',
      end_date: '2023-08'
    }
  end

  before { create_hyrax_countermetric_objects }

  describe '#as_json' do
    let(:params) do
      {
        **required_parameters,
        attributes_to_show: ['Access_Method', 'Fake_Value']
      }
    end

    it 'has the expected properties' do
      expect(subject).to be_key('Report_Header')
      expect(subject.dig('Report_Header', 'Report_Name')).to eq('Item Report')
      expect(subject.dig('Report_Header', 'Created')).to eq(created.rfc3339)
      expect(subject.dig('Report_Header', 'Report_Attributes', 'Attributes_To_Show')).to eq(['Access_Method'])
      expect(subject.dig('Report_Header', 'Report_Filters', 'Begin_Date')).to eq('2022-01-01')
      expect(subject.dig('Report_Header', 'Report_Filters', 'End_Date')).to eq('2023-08-31')
      expect(subject.dig('Report_Items', 0, 'Items', 0, 'Attribute_Performance', 0, 'Performance', 'Total_Item_Investigations', '2023-08')).to eq(2)
      expect(subject.dig('Report_Items', 0, 'Items', 0, 'Attribute_Performance', 0, 'Data_Type')).to eq('Article')
      expect(subject.dig('Report_Items', 0, 'Items', 0, 'Attribute_Performance', 0, 'Performance', 'Unique_Item_Investigations', '2023-08')).to eq(1)
      expect(subject.dig('Report_Items', 2, 'Items', 0, 'Attribute_Performance', 0, 'Performance', 'Unique_Item_Investigations', '2022-01')).to eq(1)
    end

    describe 'yop parameter' do
      context 'when provided' do
        let(:params) do
          {
            **required_parameters,
            yop: '1900-2023'
          }
        end

        it 'has a Report_Header > Report_Filters > YOP property' do
          expect(subject.dig("Report_Header", "Report_Filters", "YOP")).to eq('1900-2023')
        end
      end

      context 'when not provided' do
        it 'does not have a Report_Header > Report_Filters > YOP property' do
          expect(subject.dig("Report_Header", "Report_Filters")).not_to have_key("YOP")
        end
      end
    end
  end

  describe 'with an access_method parameter' do
    context 'that is fully valid' do
      let(:params) do
        {
          **required_parameters,
          access_method: 'regular'
        }
      end

      it 'returns the item report' do
        expect(subject.dig('Report_Header', 'Report_Filters', 'Access_Method')).to eq(['regular'])
        expect(subject.dig('Report_Items', 0, 'Items', 0, 'Attribute_Performance', 0, 'Access_Method')).to eq('Regular')
      end
    end

    context 'that is partially valid' do
      let(:params) do
        {
          **required_parameters,
          access_method: 'regular|tdm'
        }
      end

      it 'returns the item report' do
        expect(subject.dig('Report_Header', 'Report_Filters', 'Access_Method')).to eq(['regular'])
        expect(subject.dig('Report_Items', 0, 'Items', 0, 'Attribute_Performance', 0, 'Access_Method')).to eq('Regular')
      end
    end

    context 'that is invalid' do
      let(:params) do
        {
          **required_parameters,
          access_method: 'other'
        }
      end

      it 'raises an error' do
        expect { described_class.new(params, created:, account:).as_json }.to raise_error(Sushi::Error::InvalidReportFilterValueError)
      end
    end
  end

  describe 'with a yop parameter' do
    let(:params) { { yop: "2022", begin_date: '2022-01-03', end_date: '2022-12-31' } }

    # NOTE: We're already bombarding the yop coercion; this is ensuring that the SQL is valid.
    it 'filters based on that value' do
      expect(subject).to be_a(Hash)
    end
  end

  describe 'with an item_id parameter' do
    context 'that is valid' do
      context 'and metrics during the dates specified for that id' do
        let(:params) do
          {
            item_id: '54321',
            begin_date: '2022-01-03',
            end_date: '2022-04-09'
          }
        end

        it 'returns one report item' do
          expect(subject.dig('Report_Header', 'Report_Filters', 'Item_ID')).to eq('54321')
          expect(subject.dig('Report_Items', 0, 'Items', 0, 'Item')).to eq('54321')
        end
      end

      context 'and no metrics during the dates specified for that id' do
        let(:params) do
          {
            item_id: '54321',
            begin_date: '2023-06-05',
            end_date: '2023-08-09'
          }
        end

        it 'raises an error' do
          expect { described_class.new(params, created:, account:).as_json }.to raise_error(Sushi::Error::NoUsageAvailableForRequestedDatesError)
        end
      end
    end

    context 'that is invalid' do
      let(:params) do
        {
          item_id: 'qwerty123',
          begin_date: '2022-01-03',
          end_date: '2023-08-09'
        }
      end

      it 'raises an error' do
        expect { described_class.new(params, created:, account:).as_json }.to raise_error(Sushi::Error::InvalidReportFilterValueError)
      end
    end
  end

  describe 'with an author parameter' do
    context 'that is valid' do
      let(:params) do
        {
          **required_parameters,
          author: 'Tubman, Harriet'
        }
      end

      it 'returns the item report' do
        expect(subject.dig('Report_Header', 'Report_Filters', 'Author')).to eq('Tubman, Harriet')
      end
    end

    context 'that is invalid' do
      let(:params) do
        {
          **required_parameters,
          author: 'Tubman,Harriet'
        }
      end

      it 'raises an error' do
        expect { described_class.new(params, created:, account:).as_json }.to raise_error(Sushi::Error::InvalidReportFilterValueError)
      end
    end
  end

  describe 'with a platform parameter' do
    context 'that is valid' do
      let(:params) do
        {
          **required_parameters,
          platform: 'pitt.hyku.test'
        }
      end

      it 'returns the item report' do
        expect(subject.dig('Report_Header', 'Report_Filters', 'Platform')).to eq('pitt.hyku.test')
      end
    end

    context 'that is invalid' do
      let(:params) do
        {
          **required_parameters,
          platform: 'another-tenant'
        }
      end

      it 'raises an error' do
        expect { described_class.new(params, created:, account:).as_json }.to raise_error(Sushi::Error::InvalidReportFilterValueError)
      end
    end
  end

  describe 'with a metric_type parameter' do
    context 'that is valid' do
      let(:params) do
        {
          **required_parameters,
          metric_type: 'total_item_investigations'
        }
      end

      it 'returns the item report' do
        expect(subject.dig('Report_Header', 'Report_Filters', 'Metric_Type')).to eq(["Total_Item_Investigations"])
        expect(subject.dig('Report_Items', 0, 'Items', 0, 'Attribute_Performance', 0, 'Performance').length).to eq(1)
      end
    end

    context 'that is invalid' do
      let(:params) do
        {
          **required_parameters,
          metric_type: 'some_other_metric'
        }
      end

      it 'raises an error' do
        expect { described_class.new(params, created:, account:).as_json }.to raise_error(Sushi::Error::InvalidReportFilterValueError)
      end
    end
  end

  describe 'with an unrecognized parameter' do
    let(:params) { { other: 'nope' } }

    it 'raises an error' do
      expect { described_class.new(params, created:, account:).as_json }.to raise_error(Sushi::Error::UnrecognizedParameterError)
    end
  end
end
