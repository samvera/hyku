# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'the catalog under each home theme', type: :request, singletenant: true do
  let(:themes) { YAML.load_file(Rails.root.join('config', 'home_themes.yml')).keys.map(&:to_s) }

  # institutional_repository is the theme whose _controls fork carries the
  # utility links, so counting them says how many times the partial rendered
  let(:themes_with_util_links) { %w[institutional_repository] }

  # each chrome theme's /controls fork carries a class of its own, so the
  # assertion names what should be there rather than what should be missing
  let(:theme_markers) do
    { 'practice_research' => '.pr-nav', 'heritage' => '.hrt-nav', 'screening_room' => '.scr-searchbar',
      'reference' => '.ref-nav' }
  end

  it 'injects theme views only for the themes whose chrome covers these pages' do
    aggregate_failures do
      themes.each do |theme|
        allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return(theme)
        get '/catalog?q='
        doc = Nokogiri::HTML(response.body)

        if Hyku::ChromeThemes.home?(theme)
          marker = theme_markers.fetch(theme)
          expect(doc.at_css(marker)).to be_present, "#{theme} did not render its own controls (#{marker})"
        else
          expect(doc.at_css(theme_markers.values.join(', '))).to be_nil,
                                                                 "#{theme} rendered a chrome theme's controls"
        end
      end
    end
  end

  it 'names themes that exist' do
    home = YAML.load_file(Rails.root.join('config', 'home_themes.yml')).keys.map(&:to_s)
    show = YAML.load_file(Rails.root.join('config', 'show_themes.yml')).keys.map(&:to_s)

    expect(home).to include(*Hyku::ChromeThemes::HOME)
    expect(show).to include(*Hyku::ChromeThemes::SHOW)
    expect(theme_markers.keys).to match_array(Hyku::ChromeThemes::HOME)
  end

  it 'renders under every theme with one search form' do
    aggregate_failures do
      themes.each do |theme|
        allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return(theme)

        ['/catalog?q=', '/catalog/advanced', '/advanced'].each do |path|
          get path

          expect(response).to have_http_status(:ok), "#{theme} #{path} was #{response.status}"

          doc = Nokogiri::HTML(response.body)

          headers = doc.css('#search-form-header')
          expect(headers.size).to eq(1), "#{theme} #{path} rendered #{headers.size} header search forms"

          navs = doc.css('nav').count { |nav| nav.css('a').any? { |a| a['href'].to_s.include?('/about') } }
          expect(navs).to eq(1), "#{theme} #{path} rendered #{navs} site navs"
        end
      end
    end
  end

  it 'renders the control bar once per page' do
    aggregate_failures do
      themes_with_util_links.each do |theme|
        allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return(theme)

        ['/', '/contact', '/catalog?q=', '/advanced'].each do |path|
          get path

          expect(Nokogiri::HTML(response.body).css('#user_utility_links').size)
            .to eq(1), "#{theme} #{path} rendered it #{Nokogiri::HTML(response.body).css('#user_utility_links').size} times"
        end
      end
    end
  end
end
