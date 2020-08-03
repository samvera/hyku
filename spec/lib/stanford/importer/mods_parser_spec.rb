# frozen_string_literal: true

require 'importer'
require 'stanford'

RSpec.describe Stanford::Importer::ModsParser do
  let(:parser) { described_class.new(file) }
  let(:attributes) { parser.attributes }

  describe '#collection_attributes' do
    subject { parser.collection_attributes }

    let(:file) { File.join(fixture_path, 'mods', 'shpc', 'kx532cb7981.mods') }

    it "has visibility" do
      expect(subject[:visibility]).to eq 'open'
    end
  end

  describe '#record_attributes' do
    subject { parser.record_attributes }

    let(:file) { File.join(fixture_path, 'mods', 'shpc', 'druid_xv169dn4538.mods') }

    it "has visibility" do
      expect(subject[:visibility]).to eq 'open'
    end
  end
end
