# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'heritage home theme', type: :request, singletenant: true, clean_repo: true do
  let!(:work) do
    saved = Hyrax.persister.save(resource: GenericWorkResource.new(title: ['Harbor at dusk']))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  before do
    ContentBlock.featured_researcher = '<p>Dr. Miriam Okafor</p>'
    FeaturedWork.create!(work_id: work.id.to_s, order: 0)
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('heritage')
  end

  it 'renders the theme with its modules' do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('hrt-hero')

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('.hrt-rail')).to be_present
    expect(doc.at_css('.hrt-section [id="hrt-featured-heading"]')).to be_present
    expect(doc.at_css('#hrt-recent-heading')).to be_present
    expect(doc.at_css('#hrt-researcher-heading')).to be_present
  end

  it 'hides the featured works module when the tenant turns the feature off' do
    allow(Flipflop).to receive(:show_featured_works?).and_return(false)

    get root_path

    expect(Nokogiri::HTML(response.body).at_css('#hrt-featured-heading')).to be_nil
  end

  it 'hides the newly cataloged module when the tenant turns the feature off' do
    allow(Flipflop).to receive(:show_recently_uploaded?).and_return(false)

    get root_path

    expect(Nokogiri::HTML(response.body).at_css('#hrt-recent-heading')).to be_nil
  end

  it 'hides the featured researcher when the tenant turns the feature off' do
    allow(Flipflop).to receive(:show_featured_researcher?).and_return(false)

    get root_path

    expect(Nokogiri::HTML(response.body).at_css('#hrt-researcher-heading')).to be_nil
  end

  it 'hides the deposit band when the tenant turns the share button off' do
    allow(Flipflop).to receive(:show_share_button?).and_return(false)

    get root_path

    expect(Nokogiri::HTML(response.body).at_css('.hrt-cta')).to be_nil
  end
end
