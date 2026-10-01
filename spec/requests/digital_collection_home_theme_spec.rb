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
    end
  end

  describe 'content blocks' do
    it 'shows the default hero headline without marketing text, and the marketing text when set' do
      get root_path
      expect(Nokogiri::HTML(response.body).at_css('.dc-hero-plate h2.dc-hero-headline')).to be_present

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
