# frozen_string_literal: true

RSpec.describe SolrEndpoint do
  subject(:instance) { described_class.new url: 'http://example.com/solr/' }

  describe '#connection_options' do
    subject(:options) { instance.connection_options }

    it 'merges the model attributes with the application settings' do
      expect(options).to include url: 'http://example.com/solr/', read_timeout: 120
    end
  end

  describe '#connection' do
    subject { instance.connection }

    let(:result) { double }
    let(:af_options) do
      { read_timeout: 120,
        open_timeout: 120,
        url: "http://127.0.0.1:8985/solr/hydra-test" }
    end

    before do
      # Stubbing conn, because it could trigger RSolr.connect if it hadn't alredy
      # been called. This caused an error prior to stubbing for certain test seeds.
      allow(ActiveFedora::SolrService.instance).to receive(:conn)
        .and_return(double(options: af_options))
      allow(RSolr).to receive(:connect)
        .with(hash_including("read_timeout" => 120,
                             "open_timeout" => 120,
                             "url" => "http://example.com/solr/"))
        .and_return(result)
    end

    it 'returns the initialized connection (without an adapter option)' do
      expect(subject).to be result
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
end
