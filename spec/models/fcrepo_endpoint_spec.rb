# frozen_string_literal: true

RSpec.describe FcrepoEndpoint do
  let(:base_path) { 'foobar' }
  subject { described_class.new base_path: }

  it { should have_one(:account).with_foreign_key(:fcrepo_endpoint_id) }

  describe '.options' do
    it 'uses the configured application settings' do
      expect(subject.options[:base_path]).to eq base_path
    end
  end

  describe '#ping' do
    let(:success_response) { double(response: double(success?: true)) }

    it 'checks if the service is up' do
      allow(ActiveFedora::Fedora.instance.connection).to receive(:head).with(
        ActiveFedora::Fedora.instance.connection.connection.http.url_prefix.to_s
      ).and_return(success_response)
      expect(subject.ping).to be_truthy
    end

    it 'is false if the service is down' do
      allow(ActiveFedora::Fedora.instance.connection).to receive(:head).with(
        ActiveFedora::Fedora.instance.connection.connection.http.url_prefix.to_s
      ).and_raise(RuntimeError)
      expect(subject.ping).to be_falsey
    end
  end

  describe '#remove!' do
    it 'removes the base node in fedora and deletes this endpoint' do
      subject.save!
      # All of this stubbing doesn't tell us much; except that the method chain is valid.  Which is perhaps better than the two options:
      #
      # 1. Creating the Fedora node then tearing it down.
      # 2. Not testing this at all.
      #
      # What I found is that I could not stub the last receiver in the chain; as it would still
      # attempt a HEAD request.  So here is the "test".
      connection = double(ActiveFedora::CachingConnection, delete: true)
      fedora = double(ActiveFedora::Fedora, connection:)
      expect(ActiveFedora).to receive(:fedora).and_return(fedora)
      expect(connection).to receive(:delete).with(base_path)
      expect { subject.remove! }.to change(described_class, :count).by(-1)
    end
  end
end
