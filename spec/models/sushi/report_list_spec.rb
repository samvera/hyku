# frozen_string_literal: true

RSpec.describe Sushi::ReportList do
  describe '#as_json' do
    subject { described_class.new.as_json }

    it 'returns the correct format' do
      expect(subject).to be_an_instance_of(Array)
      expect(subject.length).to eq(5)
    end

    it 'has the expected keys' do
      expect(subject.last).to have_key('Report_Name')
      expect(subject.last).to have_key('Report_ID')
      expect(subject.last).to have_key('Release')
      expect(subject.last).to have_key('Report_Description')
      expect(subject.last).to have_key('Path')
      expect(subject.last).to have_key('First_Month_Available')
      expect(subject.last).to have_key('Last_Month_Available')
    end

    context 'with data in the Hyrax::CounterMetric table' do
      before { create_hyrax_countermetric_objects }

      it 'returns the expected values' do
        expect(subject.last['Report_Name']).to eq('Item Report')
        expect(subject.last['Report_ID']).to eq('ir')
        expect(subject.last['Release']).to eq('5.1')
        expect(subject.last['Report_Description']).to eq("This resource returns COUNTER 'Item Master Report' [IR].")
        expect(subject.last['Path']).to eq('/api/sushi/r51/reports/ir')
        expect(subject.last['First_Month_Available']).to be_a(String)
        expect(subject.last['Last_Month_Available']).to be_a(String)
      end
    end

    context 'without data in the Hyrax::CounterMetric table' do
      it 'returns the expected values' do
        expect(subject.last['Report_Name']).to eq('Item Report')
        expect(subject.last['Report_ID']).to eq('ir')
        expect(subject.last['Release']).to eq('5.1')
        expect(subject.last['Report_Description']).to eq("This resource returns COUNTER 'Item Master Report' [IR].")
        expect(subject.last['Path']).to eq('/api/sushi/r51/reports/ir')
        expect(subject.last['First_Month_Available']).to be_nil
        expect(subject.last['Last_Month_Available']).to be_nil
      end
    end
  end
end
