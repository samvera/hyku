# frozen_string_literal: true

RSpec.describe Hyrax::Renderers::LinkedAttributeRenderer do
  it 'searches for a value with an ampersand as written' do
    html = described_class.new(:creator, ['Allen & Ginter']).render
    link = Nokogiri::HTML(html).at_css('a')

    expect(link.text).to eq('Allen & Ginter')
    expect(CGI.parse(URI.parse(link['href']).query)['q']).to eq(['Allen & Ginter'])
  end
end
