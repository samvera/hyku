require 'importer'
require 'stanford'

RSpec.describe Stanford::Importer::ModsParser do
  let(:parser) { described_class.new(file) }
  let(:attributes) { parser.attributes }

  describe '#collection_attributes' do
    let(:file) { 'spec/fixtures/mods/shpc/kx532cb7981.mods' }

    subject { parser.collection_attributes }

    it "has visibility" do
      expect(subject[:visibility]).to eq 'open'
    end
  end

  describe '#record_attributes' do
    let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

    subject { parser.record_attributes }

    it "has visibility" do
      expect(subject[:visibility]).to eq 'open'
    end
  end
end
