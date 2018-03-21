RSpec.describe FcrepoEndpoint do
  let(:base_path) { 'foobar' }

  describe '.options' do
    subject { described_class.new base_path: base_path }

    it 'uses the configured application settings' do
      expect(subject.options[:base_path]).to eq base_path
    end
  end

  describe '#ping' do
    let(:success_response) { double(response: double(success?: true)) }

    it 'checks if the service is up' do
      allow(ActiveFedora::Fedora.instance.connection).to receive(:head).with('/').and_return(success_response)
      expect(subject.ping).to be_truthy
    end

    it 'is false if the service is down' do
      allow(ActiveFedora::Fedora.instance.connection).to receive(:head).with('/').and_raise(RuntimeError)
      expect(subject.ping).to eq false
    end
  end
end
