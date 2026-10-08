# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'the digital collection home page', type: :request, singletenant: true, clean_repo: true do
  before do
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('digital_collection')
  end

  def indexed_collection(title, visibility)
    saved = Hyrax.persister.save(
      resource: Hyrax::PcdmCollection.new(
        title: [title],
        collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s
      )
    )
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  describe 'the browse band' do
    it 'renders every readable collection and pages the rest away in the markup' do
      7.times { |n| indexed_collection("Collection #{format('%02d', n)}", 'open') }

      get root_path
      doc = Nokogiri::HTML(response.body)
      items = doc.css('[data-dc-browse-items] > li')

      expect(items.size).to eq(7)
      expect(items.count { |item| item.attribute('hidden').nil? }).to eq(6)
    end

    it 'never renders a collection the visitor cannot read' do
      indexed_collection('Public papers', 'open')
      indexed_collection('Sealed papers', 'restricted')

      get root_path

      expect(response.body).to include('Public papers')
      expect(response.body).not_to include('Sealed papers')
    end

    it 'leaves the controls and the pager out of reach until the script mounts' do
      indexed_collection('Public papers', 'open')

      get root_path
      doc = Nokogiri::HTML(response.body)

      expect(doc.at_css('[data-dc-browse-controls]').attribute('hidden')).to be_present
      expect(doc.at_css('[data-dc-browse-pager]').attribute('hidden')).to be_present
    end

    it 'says so when the tenant has no collections' do
      get root_path
      doc = Nokogiri::HTML(response.body)

      expect(doc.at_css('[data-dc-browse-items]')).to be_nil
      expect(doc.at_css('.dc-empty')).to be_present
    end

    it 'escapes a collection title into the sort key the script reads' do
      indexed_collection('Ampersand & "quotes"', 'open')

      get root_path
      title = Nokogiri::HTML(response.body).at_css('[data-dc-browse-items] > li')['data-title']

      expect(title).to eq('Ampersand & "quotes"')
    end
  end

  def indexed_work(title)
    saved = Hyrax.persister.save(resource: GenericWorkResource.new(title: [title]))
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def section_head(doc, heading_id)
    section = doc.at_css("section[aria-labelledby='#{heading_id}']")
    section&.at_css(".dc-section-head > h2.dc-section-title##{heading_id}")
  end

  describe 'browse controls' do
    before do
      indexed_collection('Harbor Photographs', 'open')
      get root_path
    end

    it 'joins the view buttons with decorative icons beside their words' do
      buttons = Nokogiri::HTML(response.body).css('.dc-view-toggle button.dc-control')

      expect(buttons.map { |b| b.text.strip }).to eq(%w[Grid List])
      expect(buttons.map { |b| b.at_css(".fa[aria-hidden='true']")['class'] }).to eq(['fa fa-th-large', 'fa fa-list'])
      expect(buttons.map { |b| b['aria-pressed'] }).to eq(%w[true false])
    end
  end

  describe 'section heads' do
    let!(:work) { indexed_work('Harbor at dusk') }

    before { FeaturedWork.create!(work_id: work.id.to_s, order: 0) }

    it 'labels the browse, featured and recent sections by the heading in their head row' do
      indexed_collection('Public papers', 'open')

      get root_path
      doc = Nokogiri::HTML(response.body)

      expect(section_head(doc, 'dc-browse-heading')).to be_present
      expect(section_head(doc, 'dc-featured-heading')).to be_present
      expect(section_head(doc, 'dc-recent-heading')).to be_present
    end

    it 'puts the view-all link for recent works in the head row' do
      get root_path

      head = Nokogiri::HTML(response.body).at_css("section[aria-labelledby='dc-recent-heading'] .dc-section-head")
      expect(head.at_css('a.dc-section-action')['href']).to include('/catalog')
    end

    it 'puts the browse view and sort controls in the head row' do
      indexed_collection('Public papers', 'open')

      get root_path

      head = Nokogiri::HTML(response.body).at_css("section[aria-labelledby='dc-browse-heading'] .dc-section-head")
      expect(head.at_css('[data-dc-browse-controls]')).to be_present
    end

    it 'drops the featured works section when the tenant turns the feature off' do
      allow(Flipflop).to receive(:show_featured_works?).and_return(false)

      get root_path

      expect(Nokogiri::HTML(response.body).at_css('#dc-featured-heading')).to be_nil
    end

    it 'drops the recent works section when the tenant turns the feature off' do
      allow(Flipflop).to receive(:show_recently_uploaded?).and_return(false)

      get root_path

      expect(Nokogiri::HTML(response.body).at_css('#dc-recent-heading')).to be_nil
    end

    context 'as an admin with a featured collection' do
      include Devise::Test::IntegrationHelpers

      before do
        Hyrax::Group.create(name: 'admin')
        collection = indexed_collection('Harbor Photographs', 'open')
        FeaturedCollection.create!(collection_id: collection.id.to_s, order: 0)
        sign_in FactoryBot.create(:admin)
      end

      it 'shows the featured collections reorder section with the same head row' do
        get root_path
        doc = Nokogiri::HTML(response.body)

        expect(section_head(doc, 'dc-fc-heading')).to be_present
        expect(doc.at_css("section[aria-labelledby='dc-fc-heading'] form .dc-reorder")).to be_present
      end

      it 'shows the featured works reorder form' do
        get root_path

        expect(Nokogiri::HTML(response.body).at_css("section[aria-labelledby='dc-featured-heading'] form .dc-reorder")).to be_present
      end

      it 'puts the collection title before its remove button and names the button' do
        get root_path
        row = Nokogiri::HTML(response.body).at_css('#ff .dd-item')
        links = row.css('a[href]').reject { |a| a['tabindex'] == '-1' }

        expect(links.map { |a| a['data-behavior'] }.last).to eq('unfeature')
        expect(links.first.text.strip).to eq('Harbor Photographs')
        expect(row.at_css('.dc-reorder-remove .sr-only').text).to eq('Remove Harbor Photographs from featured collections')
        expect(row.css('h3.float-right')).to be_empty
      end

      it 'fills each reorder form with its own list, wording and save button' do
        get root_path
        doc = Nokogiri::HTML(response.body)
        works = doc.at_css("section[aria-labelledby='dc-featured-heading'] form")
        collections = doc.at_css("section[aria-labelledby='dc-fc-heading'] form")

        expect(works.at_css('.dc-reorder#dd')['data-unfeature-confirm']).to eq(I18n.t('digital_collection.homepage.featured.unfeature_confirm'))
        expect(works.at_css('.dc-featured-hint').text).to eq(I18n.t('digital_collection.homepage.featured.reorder_hint'))
        expect(works.at_css("input[type='submit'].dc-control")['value']).to eq(I18n.t('digital_collection.homepage.featured.save_order'))
        expect(collections.at_css('.dc-reorder#ff')['data-unfeature-confirm']).to eq(I18n.t('digital_collection.homepage.featured_collections.unfeature_confirm'))
        expect(collections.at_css('.dc-featured-hint').text).to eq(I18n.t('digital_collection.homepage.featured_collections.reorder_hint'))
        expect(collections.at_css("input[type='submit'].dc-control")['value']).to eq(I18n.t('digital_collection.homepage.featured_collections.save_order'))
        expect(collections.at_css('.dc-featured-row > a.dc-featured-thumb.dc-featured-thumb-wide img')).to be_present
        expect(collections.at_css('.dc-featured-row h3.dc-featured-title a').text).to eq('Harbor Photographs')
      end

      it 'marks a work without its own thumbnail as a placeholder' do
        get root_path

        expect(Nokogiri::HTML(response.body).at_css('.dc-featured-row a.dc-featured-thumb.dc-thumb-placeholder')).to be_present
      end

      it 'lists how many works each featured collection holds' do
        get root_path

        collections = Nokogiri::HTML(response.body).at_css("section[aria-labelledby='dc-fc-heading'] form")
        expect(collections.at_css('.dc-featured-row').text).to include(I18n.t('digital_collection.homepage.browse.works_count', count: 0))
      end
    end
  end

  describe 'hero' do
    context 'with two featured collections' do
      before do
        ['Harbor Photographs', 'Maps of the Hudson'].each_with_index do |title, order|
          FeaturedCollection.create!(collection_id: indexed_collection(title, 'open').id.to_s, order:)
        end
        get root_path
      end

      let(:doc) { Nokogiri::HTML(response.body) }

      it 'labels each slide n of m' do
        slides = doc.css("#dc-hero .carousel-item[role='group'][aria-roledescription='slide']")

        expect(slides.map { |slide| slide['aria-label'] }).to eq(['Slide 1 of 2', 'Slide 2 of 2'])
      end

      it 'names each segment by its slide and marks the current one' do
        segments = doc.css('.dc-hero-segment')

        expect(segments.map { |segment| segment['aria-label'] }).to eq(['Slide 1: Harbor Photographs', 'Slide 2: Maps of the Hudson'])
        expect(segments.first['aria-current']).to eq('true')
      end

      it 'gives the pause button a pressed state' do
        expect(doc.at_css('.dc-hero-hold')['aria-pressed']).to eq('false')
      end

      it 'puts the caption label and link on the plate' do
        expect(doc.at_css('.carousel-item.active .dc-hero-caption .dc-hero-caption-label').text).to eq('Featured collection')
        expect(doc.at_css('.carousel-item.active .dc-hero-caption a.dc-hero-caption-link').text).to eq('Harbor Photographs')
        expect(doc.at_css('.carousel-item.active .dc-hero-caption a.dc-hero-caption-link')['title']).to eq('Harbor Photographs')
      end
    end

    it 'opts the carousel in to the reduced-motion hold' do
      get root_path
      expect(Nokogiri::HTML(response.body).at_css('#dc-hero[data-theme-spotlight][data-spotlight-reduced-motion]')).to be_present
    end
  end

  describe 'sparse and unusual metadata' do
    def indexed_work_with(**attributes)
      saved = Hyrax.persister.save(resource: GenericWorkResource.new(**attributes))
      Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility: 'open')
      saved.permission_manager.acl.save
      Hyrax.index_adapter.save(resource: saved)
      saved
    end

    def featured_row(title)
      doc = Nokogiri::HTML(response.body)
      doc.css("section[aria-labelledby='dc-featured-heading'] .dc-featured-row").find { |row| row.at_css('.dc-featured-title').text.strip == title }
    end

    it 'renders a featured work that has only a title, with no empty meta, description or badge' do
      work = indexed_work_with(title: ['Work with only a title'])
      FeaturedWork.create!(work_id: work.id.to_s, order: 0)

      get root_path
      row = featured_row('Work with only a title')

      expect(row).to be_present
      expect(row.at_css('.dc-featured-meta')).to be_nil
      expect(row.at_css('.dc-featured-desc')).to be_nil
      expect(row.at_css('.dc-badge')).to be_nil
      expect(row.at_css('a.dc-featured-thumb.dc-thumb-placeholder')).to be_present
    end

    it 'joins every part of the meta line a featured work has' do
      work = indexed_work_with(title: ['Dated work'], creator: ['Yamada, Tarō'], date_created: ['1923'])
      FeaturedWork.create!(work_id: work.id.to_s, order: 0)

      get root_path

      expect(featured_row('Dated work').at_css('.dc-featured-meta').text).to eq('Yamada, Tarō · 1923')
    end

    it 'shows markup in titles and descriptions as text instead of running it' do
      work = indexed_work_with(title: ['Title with <i>tags</i> & "quotes"'], description: ['<script>alert("x")</script> escaped'])
      FeaturedWork.create!(work_id: work.id.to_s, order: 0)

      get root_path
      section = Nokogiri::HTML(response.body).at_css("section[aria-labelledby='dc-featured-heading']")

      expect(section.css('script, i')).to be_empty
      expect(section.text).to include('Title with <i>tags</i> & "quotes"')
    end

    it 'keeps titles in other scripts intact' do
      title = '東京の街並み — صورة من القاهرة — Fotografía de Madrid'
      indexed_work_with(title: [title])

      get root_path

      recent = Nokogiri::HTML(response.body).at_css("section[aria-labelledby='dc-recent-heading']")
      expect(recent.css('.dc-recent-title').map { |t| t.text.strip }).to include(title)
    end

    it 'leaves the collection name off a recent work that belongs to no collection' do
      indexed_work_with(title: ['Loose work'])

      get root_path
      row = Nokogiri::HTML(response.body).css('.dc-recent-row').find { |r| r.at_css('.dc-recent-title').text.strip == 'Loose work' }

      expect(row.at_css('.dc-recent-collection')).to be_nil
    end

    it 'renders a browse card for a collection with no description' do
      indexed_collection('Collection with no description', 'open')

      get root_path
      card = Nokogiri::HTML(response.body).at_css('[data-dc-browse-items] > li .dc-collection')

      expect(card.at_css('.dc-collection-title').text.strip).to eq('Collection with no description')
      expect(card.at_css('.dc-collection-description')).to be_nil
      expect(card.at_css('.dc-collection-count')).to be_present
    end

    it 'puts a featured collection with no banner in the hero with the default image' do
      collection = indexed_collection('Unbranded collection', 'open')
      FeaturedCollection.create!(collection_id: collection.id.to_s, order: 0)

      get root_path
      slide = Nokogiri::HTML(response.body).at_css('#dc-hero .carousel-item.active')

      expect(slide.at_css('a.dc-hero-caption-link').text).to eq('Unbranded collection')
      expect(slide.at_css('img')['src']).to be_present
    end
  end

  describe 'content blocks' do
    it 'shows the default hero headline without marketing text, and the marketing text when set' do
      get root_path
      expect(Nokogiri::HTML(response.body).at_css('.dc-hero-plate h1.dc-hero-headline')).to be_present

      ContentBlock.marketing_text = '<p>Letters, maps and photographs</p>'
      get root_path
      expect(Nokogiri::HTML(response.body).at_css('.dc-hero-plate .dc-hero-headline').text).to include('Letters, maps and photographs')
    end

    it 'leaves the about band out until a heading or content is set' do
      get root_path
      expect(Nokogiri::HTML(response.body).at_css('section.dc-about')).to be_nil

      ContentBlock.find_or_create_by(name: 'homepage_about_section_content').update!(value: '<p>About the library</p>')
      get root_path
      about = Nokogiri::HTML(response.body).at_css('section.dc-about')
      expect(about.at_css('h2#dc-about-heading')).to be_present
      expect(about.text).to include('About the library')
    end

    it 'uses the about heading from the content block when one is set' do
      ContentBlock.find_or_create_by(name: 'homepage_about_section_heading').update!(value: 'Our collections')

      get root_path

      expect(Nokogiri::HTML(response.body).at_css('h2#dc-about-heading').text).to include('Our collections')
    end

    it 'leaves the deposit band out when the tenant turns the share button off' do
      allow(Flipflop).to receive(:show_share_button?).and_return(false)

      get root_path

      expect(Nokogiri::HTML(response.body).at_css('section.dc-cta')).to be_nil
    end
  end
end
