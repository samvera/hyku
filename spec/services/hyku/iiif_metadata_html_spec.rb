# frozen_string_literal: true

RSpec.describe Hyku::IiifMetadataHtml do
  describe '.sanitize' do
    it 'makes root-relative links and image sources absolute, as IIIF requires' do
      html = described_class.sanitize('<a href="/catalog">x</a><img src="/images/x.png">', base_url: 'http://test.host')

      expect(html).to eq '<a href="http://test.host/catalog">x</a><img src="http://test.host/images/x.png">'
    end

    it 'makes page-relative links and image sources absolute too' do
      html = described_class.sanitize('<a href="details">x</a><img src="images/x.png">', base_url: 'http://test.host')

      expect(html).to eq '<a href="http://test.host/details">x</a><img src="http://test.host/images/x.png">'
    end

    it 'leaves absolute and mailto links alone' do
      html = described_class.sanitize('<a href="https://example.com/a">x</a><a href="mailto:a@example.com">m</a>', base_url: 'http://test.host')

      expect(html).to eq '<a href="https://example.com/a">x</a><a href="mailto:a@example.com">m</a>'
    end
  end
end
