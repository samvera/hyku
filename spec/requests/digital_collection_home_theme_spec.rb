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
end
