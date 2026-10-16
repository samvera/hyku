# frozen_string_literal: true

RSpec.describe Hyku::S3Migration::Manifest do
  subject(:manifest) { described_class.new(client:, bucket: 'repo-bucket') }

  let(:client) { instance_double(Aws::S3::Client) }
  let(:entry) { { file_set_id: 'fs1', new_id: 'shrine://fs1/uuid', size: 3 } }

  def response(body)
    double('response', body: StringIO.new(body))
  end

  describe '#write' do
    it 'stores one JSON object per file set' do
      allow(client).to receive(:put_object)

      manifest.write(entry)

      expect(client).to have_received(:put_object).with(bucket: 'repo-bucket', key: '_migration-manifests/fs1.json', body: entry.to_json)
    end
  end

  describe '#read' do
    it 'returns the parsed entry' do
      allow(client).to receive(:get_object).with(bucket: 'repo-bucket', key: '_migration-manifests/fs1.json').and_return(response(entry.to_json))

      expect(manifest.read('fs1')).to eq entry
    end

    it 'returns nil when there is no entry' do
      allow(client).to receive(:get_object).and_raise(Aws::S3::Errors::NoSuchKey.new(nil, 'missing'))

      expect(manifest.read('nope')).to be_nil
    end
  end

  describe '#each_entry' do
    it 'yields every entry under the prefix, across pages' do
      pages = [double(contents: [double(key: 'a')]), double(contents: [double(key: 'b')])]
      allow(client).to receive(:list_objects_v2).with(bucket: 'repo-bucket', prefix: '_migration-manifests/').and_return(pages)
      allow(client).to receive(:get_object).with(bucket: 'repo-bucket', key: 'a').and_return(response({ file_set_id: 'a' }.to_json))
      allow(client).to receive(:get_object).with(bucket: 'repo-bucket', key: 'b').and_return(response({ file_set_id: 'b' }.to_json))

      expect(manifest.each_entry.map { |e| e[:file_set_id] }).to eq %w[a b]
    end
  end
end
