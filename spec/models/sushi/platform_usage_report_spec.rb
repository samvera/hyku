# frozen_string_literal:true

RSpec.describe Sushi::PlatformUsageReport do
  let(:account) { double(Account, institution_name: 'Pitt', institution_id_data: {}, cname: "pitt.edu") }
  let(:created) { Time.zone.now }
  let(:required_parameters) do
    {
      begin_date: '2022-01',
      end_date: '2022-02'
    }
  end

  describe '#as_json' do
    before { create_hyrax_countermetric_objects }

    subject { described_class.new(params, created:, account:).as_json }

    context 'with only required params' do
      let(:params) { required_parameters }

      it 'has the expected keys' do
        expect(subject).to be_key('Report_Header')
        expect(subject.dig('Report_Header', 'Created')).to eq(created.rfc3339)
        expect(subject.dig('Report_Header', 'Report_Filters', 'Begin_Date')).to eq('2022-01-01')
        expect(subject.dig('Report_Header', 'Report_Filters', 'End_Date')).to eq('2022-02-28')
        expect(subject.dig('Report_Items', 'Attribute_Performance').find { |o| o["Data_Type"] == "Platform" }.dig('Performance', 'Searches_Platform', '2022-01')).to eq(6)
      end
    end

    context 'with additional params that are not required' do
      let(:params) do
        {
          **required_parameters,
          metric_type: 'total_item_investigations|total_item_requests|fake_value',
          access_method: ['Regular']
        }
      end

      # Platform usage report should NOT show investigations, even if it is passed in the params.
      it "only shows the requested metric types, and does not include metric types that aren't allowed" do
        expect(subject.dig('Report_Header', 'Report_Filters', 'Metric_Type')).to eq(['Total_Item_Requests'])
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).to have_key('Total_Item_Requests')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).not_to have_key('Unique_Item_Requests')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).not_to have_key('Total_Item_Investigations')
        expect(subject.dig('Report_Items', 'Attribute_Performance').first.dig('Performance')).not_to have_key('Unique_Item_Investigations')
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
