# frozen_string_literal: true

RSpec.describe RedisEndpoint do
  it { should have_one(:account).with_foreign_key(:redis_endpoint_id) }

  let(:namespace) { 'foobar' }
  let(:faux_redis_instance) { double(Hyrax::RedisEventStore, ping: 'PONG', clear: true, connection:) }
  let(:connection) { double }
  before { allow(subject).to receive(:redis_instance).and_return(faux_redis_instance) }
  subject { described_class.new(namespace:) }

  describe '.options' do
    subject { described_class.new namespace: }

    it 'uses the configured application settings' do
      expect(subject.options[:namespace]).to eq namespace
    end
  end

  describe '#ping' do
    it 'checks if the service is up' do
      allow(faux_redis_instance).to receive(:ping).and_return("PONG")
      expect(subject.ping).to be_truthy
    end

    it 'is false if the service is down' do
      allow(faux_redis_instance).to receive(:ping).and_raise(RuntimeError)
      expect(subject.ping).to eq false
    end
  end

  describe '#remove!' do
    subject { described_class.create! }

    it 'clears the namespace and deletes itself' do
      expect(faux_redis_instance.connection).to receive(:clear)
      expect do
        subject.remove!
      end.to change(described_class, :count).by(-1)
    end
  end
end
