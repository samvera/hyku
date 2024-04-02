# frozen_string_literal: true

RSpec.describe SolrEndpoint do
  subject(:instance) { described_class.new url: 'http://example.com/solr/' }

  it { should have_one(:account).with_foreign_key(:solr_endpoint_id) }

  describe '#connection_options' do
    subject(:options) { instance.connection_options }

    it 'merges the model attributes with the application settings' do
      expect(options).to eq(
        "timeout" => 120,
        "open_timeout" => 120,
        "url" => "http://example.com/solr/",
        "adapter" => "solr",
        "core" => nil
      )
    end
  end

  describe '#ping' do
    let(:mock_connection) { instance_double(RSolr::Client, options: {}) }

    before do
      # Mocking on the subject, because mocking RSolr.connect causes doubles to leak for some reason
      allow(subject).to receive(:connection).and_return(mock_connection)
    end

    it 'checks if the service is up' do
      allow(mock_connection).to receive(:get).with('admin/ping').and_return('status' => 'OK')
      expect(subject.ping).to be_truthy
    end

    it 'is false if the service is down' do
      allow(mock_connection).to receive(:get).with('admin/ping').and_raise(RSolr::Error::Http.new(nil, nil))
      expect(subject.ping).to eq false
    end
  end

  describe '#remove!' do
    it 'schedules the removal and deletes the end point' do
      instance = described_class.create!
      allow(instance).to receive(:account).and_return(double(Account, search_only?: true))
      expect(RemoveSolrCollectionJob).to receive(:perform_later)
      expect { instance.remove! }.to change(described_class, :count).by(-1)
    end
  end
end
