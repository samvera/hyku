# frozen_string_literal:true

RSpec.describe Sushi::ServerStatus do
  describe '#server_status' do
    subject { described_class.new(account:).server_status }

    let(:account) { double(Account, cname: 'pitt.hyku.test') }

    it 'returns the correct format' do
      expect(subject).to be_an_instance_of(Array)
      expect(subject.length).to eq(1)
    end

    it 'has the expected keys' do
      expect(subject.first).to have_key('Description')
      expect(subject.first).to have_key('Service_Active')
      expect(subject.first).to have_key('Registry_Record')
    end

    it 'returns the expected values' do
      expect(subject.first['Description']).to eq("COUNTER Usage Reports for #{account.cname} platform.")
      expect(subject.first['Service_Active']).to eq(true)
      expect(subject.first['Registry_Record']).to eq("")
    end
  end
end
