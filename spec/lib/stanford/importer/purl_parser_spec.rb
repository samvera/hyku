# frozen_string_literal: true

require 'stanford'

RSpec.describe Stanford::Importer::PurlParser do
  let(:xml) { fixture_file('purl/bc390xk2647.xml').read }
  let(:parser) { described_class.new(xml) }

  describe "attributes" do
    subject { parser.attributes }

    it "has required attributes" do
      expect(subject[:title]).to eq ['Lake Lagunita']
      expect(subject[:subject]).to eq ['Lake Lagunita']
      expect(subject[:language]).to eq ['en']
      expect(subject[:collection]).to eq(id: 'kx532cb7981',
                                         title: ['Stanford historical photograph collection, 1887-circa 1996'])
      expect(subject[:visibility]).to eq 'open'
      expect(subject[:id]).to eq 'bc390xk2647'
    end
  end
end
