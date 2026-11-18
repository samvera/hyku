# frozen_string_literal: true

RSpec.describe 'Locale in generated links', type: :request, singletenant: true do
  # The language picker links are "?locale=xx" by design, so only the other links are checked.
  def link_locales
    Nokogiri::HTML(response.body).css('a[href]').map { |a| a['href'] }
            .reject { |href| href.start_with?('?locale=') }
            .filter_map { |href| href[/[?&]locale=([^&#]+)/, 1] }
  end

  it 'leaves the default locale out of links' do
    get '/'

    expect(response).to have_http_status(:ok)
    expect(link_locales).to be_empty
  end

  it 'uses only the chosen locale in links' do
    get '/?locale=it'

    expect(link_locales).not_to be_empty
    expect(link_locales.uniq).to eq ['it']
  end

  it 'does not carry a chosen locale into later default-locale requests' do
    get '/?locale=it'
    get '/'

    expect(link_locales).to be_empty
  end
end
