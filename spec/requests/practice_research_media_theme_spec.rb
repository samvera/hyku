# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'practice_research_media theme', type: :request, singletenant: true, clean_repo: true do
  before do
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('practice_research_media')
  end

  it 'is registered as a selectable home theme' do
    themes = YAML.load_file(Rails.root.join('config', 'home_themes.yml'))
    expect(themes['practice_research_media']).to include('name' => 'Practice Research - Media',
                                                         'parent' => 'practice_research')
  end

  it 'renders the variant over the practice_research base' do
    get '/'

    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('body')['class'].split).to include('practice_research_media', 'practice_research')
    expect(response.body).to include('pr-home-media')
    expect(response.body).to include('pr-hero')
  end
end
