# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'screening room home theme', type: :request, singletenant: true, clean_repo: true do
  def indexed(resource, visibility = 'open')
    saved = Hyrax.persister.save(resource:)
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_work(title, visibility)
    saved = Hyrax.persister.save(resource: GenericWorkResource.new(title: [title]))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  let!(:work) { indexed_work('Harbor at dusk', 'open') }

  before do
    FeaturedWork.create!(work_id: work.id.to_s, order: 0)
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('screening_room')
  end

  it 'renders the spotlight for a featured work' do
    get root_path

    expect(response).to have_http_status(:ok)

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('#scr-spotlight')).to be_present
    expect(doc.at_css('.scr-stage-title').text).to include('Harbor at dusk')
  end

  it 'hides the spotlight when the tenant turns featured works off' do
    allow(Flipflop).to receive(:show_featured_works?).and_return(false)

    get root_path

    expect(Nokogiri::HTML(response.body).at_css('#scr-spotlight')).to be_nil
  end

  it 'renders no spotlight when nothing is featured' do
    FeaturedWork.destroy_all

    get root_path

    expect(Nokogiri::HTML(response.body).at_css('#scr-spotlight')).to be_nil
  end

  it 'never leaks a featured work the visitor cannot read' do
    private_work = indexed_work('Unreleased reel', 'restricted')
    FeaturedWork.create!(work_id: private_work.id.to_s, order: 1)

    get root_path

    expect(response.body).not_to include('Unreleased reel')
    expect(Nokogiri::HTML(response.body).css('.carousel-item').size).to eq(1)
  end

  it 'offers no player when the work has no readable representative' do
    get root_path

    expect(Nokogiri::HTML(response.body).at_css('.scr-player')).to be_nil
  end

  it 'opens a readable image representative in the lightbox' do
    allow_any_instance_of(SolrDocument).to receive(:image?).and_return(true)
    allow_any_instance_of(SolrDocument).to receive(:original_file_id).and_return('file-abc')
    file_set = indexed(Hyrax::FileSet.new(title: ['plate-001.tif']))
    plate = indexed(GenericWorkResource.new(title: ['Harbor plate'], member_ids: [file_set.id],
                                            representative_id: file_set.id))
    FeaturedWork.create!(work_id: plate.id.to_s, order: 1)

    get root_path

    modal = Nokogiri::HTML(response.body).at_css("#scr-player-#{plate.id}")
    expect(modal.at_css('img.scr-player-image')['src']).to include('file-abc')
    expect(modal.at_css('img.scr-player-image')['alt']).to eq('plate-001.tif')
  end

  it 'plays a readable audio representative in the quick view modal' do
    allow_any_instance_of(SolrDocument).to receive(:audio?).and_return(true)
    file_set = indexed(Hyrax::FileSet.new(title: ['interview-001.mp3']))
    interview = indexed(GenericWorkResource.new(title: ['Oral history, side A'], member_ids: [file_set.id],
                                                representative_id: file_set.id))
    FeaturedWork.create!(work_id: interview.id.to_s, order: 1)

    get root_path

    modal = Nokogiri::HTML(response.body).at_css("#scr-player-#{interview.id}")
    expect(modal.at_css('audio.scr-player-media')).to be_present
    expect(modal.css('audio source').map { |source| source['type'] }).to eq(['audio/ogg', 'audio/mpeg'])
  end

  it 'offers no player when the tenant has downloads turned off' do
    allow_any_instance_of(SolrDocument).to receive(:video?).and_return(true)
    allow_any_instance_of(Ability).to receive(:test_download).and_return(false)
    file_set = indexed(Hyrax::FileSet.new(title: ['reel-002.mp4']))
    sealed = indexed(GenericWorkResource.new(title: ['Sealed reel'], member_ids: [file_set.id],
                                             representative_id: file_set.id))
    FeaturedWork.create!(work_id: sealed.id.to_s, order: 1)

    get root_path

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css("#scr-player-#{sealed.id}")).to be_nil
    expect(doc.css('.scr-action-primary')).to be_empty
  end

  it 'plays a readable video representative in the quick view modal' do
    allow_any_instance_of(SolrDocument).to receive(:video?).and_return(true)
    file_set = indexed(Hyrax::FileSet.new(title: ['reel-001.mp4']))
    reel = indexed(GenericWorkResource.new(title: ['Coaling a battleship'], member_ids: [file_set.id],
                                           representative_id: file_set.id))
    FeaturedWork.create!(work_id: reel.id.to_s, order: 1)

    get root_path

    modal = Nokogiri::HTML(response.body).at_css("#scr-player-#{reel.id}")
    expect(modal.at_css('video.scr-player-media')).to be_present
    expect(modal.css('video source').map { |source| source['type'] }).to eq(['video/webm', 'video/mp4'])
  end

  context 'as a user who can reorder the featured collections' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:collection) { indexed(Hyrax::PcdmCollection.new(title: ['Newsreels'])) }

    before do
      indexed(GenericWorkResource.new(title: ['Filed reel'], member_of_collection_ids: [collection.id]))
      FeaturedCollection.create!(collection_id: collection.id.to_s, order: 0)
      login_as(admin, scope: :user)
    end

    it 'counts the works in each card it hands the editor to reorder' do
      get root_path

      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.scr-reorder-cards .featured-item')).to be_present
      expect(doc.at_css('.scr-collection-meta').text.strip).to eq('1 work')
    end
  end

  context 'as a user who can reorder the featured works' do
    let(:admin) { FactoryBot.create(:admin) }

    before { login_as(admin, scope: :user) }

    it 'renders the reorder list alongside the public spotlight' do
      get root_path

      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('#scr-spotlight')).to be_present
      expect(doc.at_css('.scr-reorder')).to be_present
      expect(doc.at_css('.featured-item')).to be_present
    end
  end

  it 'cuts a long spotlight title rather than letting the stage grow' do
    long = indexed_work('A very long featured work title that runs on and on describing the reel, its provenance and its transfer', 'open')
    FeaturedWork.create!(work_id: long.id.to_s, order: 1)

    get root_path

    titles = Nokogiri::HTML(response.body).css('.scr-stage-title').map { |t| t.text.strip }
    cut = titles.find { |title| title.start_with?('A very long featured') }

    expect(cut.length).to be <= 80
    expect(cut).to end_with('...')
  end

  describe 'the spotlight hold control' do
    it 'offers a way to stop the rotation when more than one work is featured' do
      second = indexed_work('Night crossing', 'open')
      FeaturedWork.create!(work_id: second.id.to_s, order: 1)

      get root_path

      button = Nokogiri::HTML(response.body).at_css('[data-scr-spotlight-hold]')
      expect(button.text.strip).to eq('Pause')
      expect(button['data-resume-label']).to eq('Play')
    end

    it 'leaves the control out when a single work cannot rotate' do
      get root_path

      expect(Nokogiri::HTML(response.body).at_css('[data-scr-spotlight-hold]')).to be_nil
    end
  end

  describe 'the lede band' do
    it 'renders the home page text with the holdings counts' do
      ContentBlock.home_text = '<p>What the archive holds.</p>'

      get root_path

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.scr-lede-text').text).to include('What the archive holds')
      expect(doc.css('.scr-count-value').map { |c| c.text.strip }).to eq(%w[1 0])
    end

    it 'keeps the counts when no home page text is set' do
      ContentBlock.home_text = ''

      get root_path

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.scr-lede-text')).to be_nil
      expect(doc.css('.scr-count-value').map { |c| c.text.strip }).to eq(%w[1 0])
    end
  end

  describe 'the collections section' do
    it 'hides the section, heading included, when the tenant has no collections' do
      get root_path

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.scr-collections')).to be_nil
      expect(doc.at_css('#scr-collections-heading')).to be_nil
    end
  end

  describe 'the latest additions list' do
    it 'dates a work by how long ago it was deposited' do
      get root_path

      item = Nokogiri::HTML(response.body).css('.scr-recent-item')
                     .find { |row| row.text.include?('Harbor at dusk') }
      stamp = item.at_css('.scr-recent-date')

      expect(stamp.text.strip).to end_with('ago')
      expect(stamp['datetime']).to be_present
    end

    it 'leaves a work the visitor cannot read out of the list' do
      indexed_work('Unreleased reel', 'restricted')

      get root_path

      doc = Nokogiri::HTML(response.body)
      expect(doc.css('.scr-recent-item').text).to include('Harbor at dusk')
      expect(doc.css('.scr-recent-item').text).not_to include('Unreleased reel')
    end

    it 'hides the list when the tenant turns recently uploaded off' do
      allow(Flipflop).to receive(:show_recently_uploaded?).and_return(false)

      get root_path

      expect(Nokogiri::HTML(response.body).at_css('.scr-recent')).to be_nil
    end
  end

  describe 'the featured researcher' do
    it 'renders the content block inside the card' do
      ContentBlock.featured_researcher = '<h3>Dr. Miriam Okafor</h3>'

      get root_path

      expect(Nokogiri::HTML(response.body).at_css('.scr-researcher-prose').text).to include('Dr. Miriam Okafor')
    end

    it 'drops the row entirely when neither the list nor the researcher shows' do
      allow(Flipflop).to receive(:show_recently_uploaded?).and_return(false)
      ContentBlock.featured_researcher = ''

      get root_path

      expect(Nokogiri::HTML(response.body).at_css('.scr-recent-row')).to be_nil
    end
  end

  describe 'the about band' do
    it 'falls back to the theme heading when the tenant set only the content' do
      ContentBlock.find_or_create_by(name: 'homepage_about_section_content')
                  .update(value: '<p>The archive holds paper print survivals.</p>')

      get root_path

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('#scr-about-heading').text.strip).to eq('About the collections')
      expect(doc.at_css('.scr-about-prose').text).to include('paper print survivals')
    end

    it 'hides the band when the tenant set neither block' do
      get root_path

      expect(Nokogiri::HTML(response.body).at_css('.scr-about')).to be_nil
    end
  end

  describe 'the deposit band' do
    it 'sends a visitor who is not signed in to the login gate' do
      get root_path

      button = Nokogiri::HTML(response.body).at_css('.scr-cta-button')
      expect(button['href']).to eq(hyrax.my_works_path)
    end

    it 'hides the band when the tenant turns the share button off' do
      allow(Flipflop).to receive(:show_share_button?).and_return(false)

      get root_path

      expect(Nokogiri::HTML(response.body).at_css('.scr-cta')).to be_nil
    end
  end
end
