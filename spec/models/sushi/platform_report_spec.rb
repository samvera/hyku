# frozen_string_literal:true

RSpec.describe Sushi::PlatformReport do
  subject { described_class.new(params, created:, account:).to_hash }

  let(:account) { double(Account, institution_name: 'Pitt', institution_id_data: {}, cname: 'pitt.hyku.test') }
  let(:created) { Time.zone.now }
  let(:required_parameters) do
    {
      begin_date: '2022-01',
      end_date: '2022-02'
    }
  end

  before { create_hyrax_countermetric_objects }

  describe '#as_json' do
    context 'with only required params' do
      let(:params) { required_parameters }

      it 'has the expected keys' do
        expect(subject).to be_key('Report_Header')
        expect(subject.dig('Report_Header', 'Created')).to eq(created.rfc3339)
        expect(subject.dig('Report_Header', 'Report_Filters', 'Begin_Date')).to eq('2022-01-01')
        expect(subject.dig('Report_Header', 'Report_Filters', 'End_Date')).to eq('2022-02-28')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance', 'Total_Item_Investigations', '2022-01')).to eq(6)
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance', 'Total_Item_Requests', '2022-01')).to eq(19)
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance', 'Unique_Item_Investigations', '2022-01')).to eq(3)
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance', 'Unique_Item_Requests', '2022-01')).to eq(3)
        expect(subject.dig('Report_Items', 'Attribute_Performance').find { |o| o["Data_Type"] == "Platform" }.dig('Performance', 'Searches_Platform', '2022-01')).to eq(6)
        # It should not include that 2021 data.
        expect(subject.dig('Report_Items', 'Attribute_Performance', 0, 'Performance', 'Total_Item_Investigations')).to eq("2022-01" => 6)
      end
    end

    context 'when given metric_types searches_platform AND total_item_requests' do
      let(:params) do
        {
          begin_date: '2023-08',
          end_date: '2023-09',
          metric_type: 'total_item_requests|searches_platform'
        }
      end

      it 'includes the platform data type and the article data type (which is the only data type within the date range' do
        expect(subject.dig('Report_Items', 'Attribute_Performance').map { |ap| ap['Data_Type'] }.sort).to match_array(['Article', 'Platform'])
      end
    end
    context 'when given a non-platform data_type and omit searches platform' do
      let(:params) do
        {
          begin_date: '2023-08',
          end_date: '2023-09',
          data_type: 'article',
          attributes_to_show: ['Access_Method', 'Fake_Value'],
          granularity: 'totals'
        }
      end

      it 'omits the platform data type' do
        expect(subject.dig('Report_Items', 'Attribute_Performance').detect { |dt| dt['Data_Type']['Platform'] }).to be_nil
      end
    end

    context 'with additional params that are not required' do
      let(:params) do
        {
          begin_date: '2023-08',
          end_date: '2023-09',
          metric_type: 'total_item_investigations|unique_item_investigations|fake_value',
          data_type: 'article',
          attributes_to_show: ['Access_Method', 'Fake_Value'],
          granularity: 'totals'
        }
      end

      it "only shows the requested metric types, and does not include metric types that aren't allowed" do
        expect(subject.dig('Report_Header', 'Report_Filters', 'Metric_Type')).to eq(['Total_Item_Investigations', 'Unique_Item_Investigations'])
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).to have_key('Total_Item_Investigations')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).to have_key('Unique_Item_Investigations')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).not_to have_key('Total_Item_Requests')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).not_to have_key('Unique_Item_Requests')
      end

      it "includes the correct attributes to show, and does not include attributes that aren't allowed" do
        expect(subject.dig('Report_Header', 'Report_Attributes', 'Attributes_To_Show')).to eq(['Access_Method'])
      end

      it 'does not show title requests/investigations for non-book resource types' do
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).not_to have_key('Unique_Title_Requests')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).not_to have_key('Unique_Title_Investigations')
      end

      it 'sums the totals for each metric type' do
        expect(subject.dig('Report_Header', 'Report_Attributes', 'Granularity')).to eq('Totals')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance', 'Total_Item_Investigations', 'Totals')).to be_a(Integer)
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
        expect(subject.dig('Report_Items', 'Attribute_Performance', 0, 'Access_Method')).to eq('Regular')
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
        expect(subject.dig('Report_Items', 'Attribute_Performance', 0, 'Access_Method')).to eq('Regular')
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

  describe 'with an unrecognized parameter' do
    let(:params) { { other: 'nope' } }

    it 'raises an error' do
      expect { described_class.new(params, created:, account:).as_json }.to raise_error(Sushi::Error::UnrecognizedParameterError)
    end
  end
end
