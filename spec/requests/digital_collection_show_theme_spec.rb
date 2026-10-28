# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'digital_collection_show theme', type: :request, singletenant: true, clean_repo: true do
  include Devise::Test::IntegrationHelpers

  let(:admin) { FactoryBot.create(:admin) }
  let(:file_set) { valkyrie_create(:hyrax_file_set, title: ['harbor-0001.jpg'], visibility_setting: 'open') }
  let(:child_work) { indexed(GenericWorkResource.new(title: ['Detail scan, piers and schooner'])) }
  let(:parent) { indexed(GenericWorkResource.new(title: ['The Harbor'], member_ids: [file_set.id, child_work.id])) }

  def indexed(resource)
    saved = Hyrax.persister.save(resource:)
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_with_visibility(resource, visibility)
    saved = Hyrax.persister.save(resource:)
    Hyrax::VisibilityWriter.new(resource: saved).assign_access_for(visibility:)
    saved.permission_manager.acl.save
    Hyrax.index_adapter.save(resource: saved)
    saved
  end

  def indexed_collection(title, visibility = 'open')
    collection = indexed_with_visibility(
      Hyrax::PcdmCollection.new(
        title: [title],
        collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s
      ),
      visibility
    )
    Hyrax::PermissionTemplate.find_or_create_by!(source_id: collection.id.to_s)
    collection
  end

  before do
    Hyrax::Group.create(name: 'admin')
    sign_in admin
    allow_any_instance_of(ApplicationController).to receive(:show_page_theme).and_return('digital_collection_show')
  end

  describe 'the work page' do
    it 'renders the theme shell with the title, a type badge and the rail' do
      get "/concern/generic_works/#{parent.id}"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.dc-show h1.dc-show-title').text).to include('The Harbor')
      expect(doc.at_css('.dc-show-badges .dc-badge')).to be_present
      expect(doc.at_css('aside.dc-show-rail')).to be_present
      expect(doc.at_css('.dc-meta h2#dc-meta-label')).to be_present
    end

    it 'renders a work with no creation date, and puts the author and date in the byline when present' do
      undated = indexed(GenericWorkResource.new(title: ['Undated record']))
      dated = indexed(GenericWorkResource.new(title: ['Dated record'], creator: ['Detroit Publishing Co.'], date_created: ['1905']))

      get "/concern/generic_works/#{undated.id}"
      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css('.dc-show-byline')).to be_nil

      get "/concern/generic_works/#{dated.id}"
      expect(Nokogiri::HTML(response.body).at_css('.dc-show-byline').text).to include('Detroit Publishing Co.', '1905')
    end

    it 'lists files and child works together in the items panel' do
      get "/concern/generic_works/#{parent.id}"

      panel = Nokogiri::HTML(response.body).at_css('section#dc-items')
      expect(panel.at_css('h2.dc-panel-label#dc-items-label')).to be_present
      expect(panel.css('.dc-item-row').size).to eq(2)
      expect(panel.text).to include('harbor-0001.jpg', 'Detail scan, piers and schooner')
      expect(panel.at_css('.dc-panel-count').text.strip).to eq('2')
    end

    it 'shows an editor the empty items panel on a work with no members' do
      empty = indexed(GenericWorkResource.new(title: ['Empty record']))

      get "/concern/generic_works/#{empty.id}"

      panel = Nokogiri::HTML(response.body).at_css('section#dc-items')
      expect(panel.at_css('.dc-panel-empty')).to be_present
      expect(panel.at_css('.dc-item-list')).to be_nil
    end

    it 'shows the viewer placeholder when there is nothing to view' do
      empty = indexed(GenericWorkResource.new(title: ['Empty record']))

      get "/concern/generic_works/#{empty.id}"

      expect(Nokogiri::HTML(response.body).at_css('.dc-viewer.dc-viewer-empty .dc-viewer-placeholder')).to be_present
    end

    it 'lists what the work belongs to in the part-of panel' do
      collection = indexed_collection('Photograph Collections')
      filed = indexed_with_visibility(
        GenericWorkResource.new(title: ['Filed away'], member_of_collection_ids: [collection.id]), 'open'
      )

      get "/concern/generic_works/#{filed.id}"

      panel = Nokogiri::HTML(response.body).at_css('section.dc-part-of')
      expect(panel.at_css('h2.dc-panel-label#dc-part-of-label')).to be_present
      expect(panel.text).to include('Photograph Collections')
      expect(panel.css('dt').map { |dt| dt.text.strip }).to eq(['Collection'])
    end

    it 'leaves the part-of panel out when the work belongs to nothing' do
      get "/concern/generic_works/#{parent.id}"

      expect(Nokogiri::HTML(response.body).at_css('section.dc-part-of')).to be_nil
    end

    it 'offers the citation styles with a copy control and an EndNote export' do
      cited = indexed(GenericWorkResource.new(title: ['The Harbor'], creator: ['Detroit Publishing Co.']))

      get "/concern/generic_works/#{cited.id}"

      card = Nokogiri::HTML(response.body).at_css('section.dc-cite')
      expect(card.css('.dc-cite-picker option').map { |o| o['value'] }).to eq(%w[apa mla chicago])
      expect(card.css('[data-citation-text]').size).to eq(3)
      expect(card.css('[data-citation-text]:not([hidden])').size).to eq(1)
      expect(card.at_css('button.dc-copy[data-citation-copy] ~ span.dc-copied[data-citation-copied]')).to be_present
      expect(card.at_css('.dc-cite-export')['href']).to include('endnote')
    end

    it 'keeps the export when a work has no author to build a citation from' do
      get "/concern/generic_works/#{parent.id}"

      card = Nokogiri::HTML(response.body).at_css('section.dc-cite')
      expect(card.at_css('.dc-cite-picker')).to be_nil
      expect(card.at_css('.dc-cite-export')['href']).to include('endnote')
    end

    it 'shows the editor controls above the title' do
      get "/concern/generic_works/#{parent.id}"

      labels = Nokogiri::HTML(response.body).css('.dc-show-actions-inner > .btn:not(.collapse), .dc-show-actions-inner > .btn-group > .btn')
      expect(labels.map { |btn| btn.text.strip }).to eq(['Edit', 'Add to collection', 'Attach Child', 'File Manager', 'Delete'])
      expect(labels.first['class']).to include('dc-action-primary')
      expect(labels.last['class']).to include('dc-action-danger')
    end

    it 'leaves the title and description out of Item details, since the page shows them above it' do
      described = indexed(GenericWorkResource.new(title: ['The Harbor'], description: ['Piers at dawn.'], creator: ['Detroit Publishing Co.']))

      get "/concern/generic_works/#{described.id}"

      rows = Nokogiri::HTML(response.body).css('.dc-meta dl.dc-meta-rows > div')
      expect(rows.map { |row| row.at_css('dt').text.strip }).to include('Creator')
      expect(rows.map { |row| row.at_css('dt').text.strip }).not_to include('Title', 'Description')
      expect(rows).to all(satisfy { |row| row.at_css('dt') && row.at_css('dd') })
    end

    it 'labels the citation style picker and the copy button' do
      cited = indexed(GenericWorkResource.new(title: ['The Harbor'], creator: ['Detroit Publishing Co.']))

      get "/concern/generic_works/#{cited.id}"

      card = Nokogiri::HTML(response.body).at_css('section.dc-cite')
      expect(card.at_css("label[for='dc-cite-picker']").text).to eq('Citation style')
      expect(card.at_css('button.dc-copy').text.strip).to eq('Copy citation')
    end

    it 'shows editors the administrative set under Part of' do
      admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
      managed = indexed(GenericWorkResource.new(title: ['Managed record'], admin_set_id: admin_set.id))

      get "/concern/generic_works/#{managed.id}"

      panel = Nokogiri::HTML(response.body).at_css('section.dc-part-of')
      expect(panel.css('dt').map { |dt| dt.text.strip }).to eq(['Administrative set'])
      expect(panel.at_css('dd a').text).to eq(admin_set.title.first)
    end

    it 'renders the digital collection masthead and the secondary header' do
      get "/concern/generic_works/#{parent.id}"

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('body')['class']).to include('digital_collection_show')
      expect(doc.at_css('.dc-secondary-header .dc-secondary-header-search form')).to be_present
    end

    it 'puts the search before the breadcrumbs in the page code, as phones show them' do
      get "/concern/generic_works/#{parent.id}"

      parts = Nokogiri::HTML(response.body).at_css('.dc-secondary-header-inner').element_children.map { |el| el['class'] }
      expect(parts).to eq(%w[dc-secondary-header-search dc-breadcrumbs])
    end

    context 'as a visitor' do
      let(:public_parent) do
        indexed_with_visibility(GenericWorkResource.new(title: ['Public harbor'], member_ids: [file_set.id]), 'open')
      end

      before { sign_out admin }

      it 'hides the editor controls and the empty-panel hint' do
        empty = indexed_with_visibility(GenericWorkResource.new(title: ['Public empty']), 'open')

        get "/concern/generic_works/#{public_parent.id}"
        doc = Nokogiri::HTML(response.body)
        expect(doc.css('.dc-show-actions-inner > .btn:not(.collapse), .dc-show-actions-inner > .btn-group')).to be_empty

        get "/concern/generic_works/#{empty.id}"
        expect(Nokogiri::HTML(response.body).at_css('section#dc-items')).to be_nil
      end

      it 'hides the administrative set from visitors' do
        admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
        managed = indexed_with_visibility(GenericWorkResource.new(title: ['Managed record'], admin_set_id: admin_set.id), 'open')

        get "/concern/generic_works/#{managed.id}"

        expect(Nokogiri::HTML(response.body).at_css('section.dc-part-of')).to be_nil
      end
    end

    it 'hides an unreadable child work from the items panel' do
      restricted = indexed_with_visibility(GenericWorkResource.new(title: ['Private Child']), 'restricted')
      readable = indexed_with_visibility(GenericWorkResource.new(title: ['Readable Child']), 'open')
      mixed = indexed_with_visibility(
        GenericWorkResource.new(title: ['Mixed access record'], member_ids: [restricted.id, readable.id]), 'open'
      )
      sign_in FactoryBot.create(:user)

      get "/concern/generic_works/#{mixed.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Readable Child')
      expect(response.body).not_to include('Private Child')
    end
  end

  describe 'the items pager' do
    let(:paged) do
      files = Array.new(5) { |n| valkyrie_create(:hyrax_file_set, title: ["page-#{n + 1}.jpg"], visibility_setting: 'open') }
      indexed(GenericWorkResource.new(title: ['Paged record'], member_ids: files.map(&:id)))
    end

    def pager_items(page)
      get "/concern/generic_works/#{paged.id}", params: { rows: 1, page: }
      Nokogiri::HTML(response.body).css('.dc-panel-pager li.page-item')
    end

    def labels(items)
      items.map { |li| li.at_css('.page-link').children.first.text.strip }
    end

    it 'keeps the first, current and last pages for phones and marks the rest as full width only' do
      items = pager_items(3)

      expect(labels(items.reject { |li| li['class'].include?('dc-page-full') })).to eq(%w[Previous Next 1 … 3 … 5])
      expect(labels(items.reject { |li| li['class'].include?('dc-page-compact') })).to eq(%w[Previous Next 1 2 3 4 5])
    end

    it 'adds no phone gap where no pages are skipped' do
      expect(labels(pager_items(2).select { |li| li['class'].include?('dc-page-compact') })).to eq(%w[…])
      expect(labels(pager_items(4).select { |li| li['class'].include?('dc-page-compact') })).to eq(%w[…])
      expect(pager_items(5).count { |li| li['class'].include?('dc-page-compact') }).to eq(1)
    end
  end

  describe 'the secondary header' do
    let(:collection) { indexed_collection('Harbor Photographs') }
    let(:filed) do
      indexed_with_visibility(GenericWorkResource.new(title: ['Filed away'], member_ids: [file_set.id], member_of_collection_ids: [collection.id]), 'open')
    end
    let(:from_search) { { 'HTTP_REFERER' => "http://#{host}/catalog?q=harbor" } }

    def trail
      Nokogiri::HTML(response.body).css('nav.dc-breadcrumbs li').map { |li| li.text.strip }
    end

    it 'leads a collection page back to the search it came from' do
      get "/collections/#{collection.id}", headers: from_search

      expect(trail).to eq(['Home', 'Harbor Photographs', 'Back to search results'])
      expect(Nokogiri::HTML(response.body).at_css('nav.dc-breadcrumbs [aria-current="page"]').text).to eq('Harbor Photographs')
    end

    it 'leaves out the search link when the reader did not come from a search' do
      get "/collections/#{collection.id}"

      expect(trail).to eq(['Home', 'Harbor Photographs'])
    end

    it 'puts the collection between Home and a work' do
      get "/concern/generic_works/#{filed.id}", headers: from_search

      expect(trail).to eq(['Home', 'Harbor Photographs', 'Filed away', 'Back to search results'])
    end

    it 'skips the collection for a work in no collection' do
      get "/concern/generic_works/#{parent.id}"

      expect(trail).to eq(['Home', 'The Harbor'])
    end

    it 'leads a file back through its collection and work' do
      filed
      get "/concern/file_sets/#{file_set.id}"

      expect(trail).to eq(['Home', 'Harbor Photographs', 'Filed away'])
      expect(Nokogiri::HTML(response.body).css('nav.dc-breadcrumbs a').last['href']).to include(filed.id.to_s)
    end

    it 'renders one breadcrumb trail per page, with a translated label' do
      get "/concern/generic_works/#{filed.id}", params: { locale: 'de' }
      doc = Nokogiri::HTML(response.body)

      expect(doc.css('nav.dc-breadcrumbs, .breadcrumb').size).to eq(1)
      expect(doc.at_css('nav.dc-breadcrumbs')['aria-label']).to eq('Brotkrümelnavigation')
    end
  end

  describe 'the file set page' do
    let(:doc) { Nokogiri::HTML(response.body) }

    before { parent }

    it 'puts the preview, share icons, file actions and single-use links in the aside' do
      get "/concern/file_sets/#{file_set.id}"
      aside = doc.at_css('aside.dc-file-aside')

      expect(aside.at_css('.dc-file-media')).to be_present
      expect(aside.css('.dc-file-share a.dc-share-link').map { |a| a.at_css('.sr-only').text.squish })
        .to eq(['Facebook (opens in a new tab)', 'X (opens in a new tab)', 'Email'])
      expect(aside.css('.dc-file-share a.dc-share-link').map { |a| a.xpath('text()').text.strip }).to all(be_empty)
      expect(aside.css('.dc-file-actions a').map { |a| a.text.squish }).to eq(['Edit this file set', 'Delete this file set'])
      expect(aside.at_css('.dc-file-actions .dc-action-danger')['data-confirm']).to be_present
      expect(aside.at_css('section.dc-file-links h2').text.strip).to eq('Single-Use Links')
      expect(aside.at_css('.generate-single-use-link').text.strip).to eq('Generate download link')
    end

    it 'leaves out the share icons when the admin hides social buttons' do
      allow(Flipflop).to receive(:hide_social_buttons?).and_return(true)
      get "/concern/file_sets/#{file_set.id}"

      expect(doc.at_css('.dc-file-share')).to be_nil
    end

    it 'shows the title with its badge, then Description, File details and Activity' do
      get "/concern/file_sets/#{file_set.id}"

      expect(doc.css('h1').map { |h| h.text.strip }).to eq(['harbor-0001.jpg'])
      expect(doc.at_css('.dc-file-title .badge')).to be_present
      expect(doc.css('.dc-file-main .dc-section-title').map(&:text)).to eq(['File details', 'Activity'])
      expect(doc.css('.dc-file-main dt').map { |dt| dt.text.strip }).not_to include('Title')
    end

    it 'lists file details in plain words and says when the file is not characterized' do
      get "/concern/file_sets/#{file_set.id}"
      terms = doc.css("section[aria-labelledby='dc-file-details-label'] > dl dt").map { |dt| dt.text.strip }

      expect(terms).to eq(['Date uploaded', 'Date modified', 'Fixity check', 'Technical details'])
      expect(doc.at_css('details.dc-file-technical')).to be_nil
    end

    it 'keeps the full characterization list in a closed Technical details section' do
      allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:characterized?).and_return(true)
      allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:characterization_metadata).and_return(byte_order: ['big endian'])
      allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:primary_characterization_values).and_return(['big endian'])
      allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:secondary_characterization_values).and_return([])
      get "/concern/file_sets/#{file_set.id}", params: { locale: 'es' }
      details = doc.at_css('details.dc-file-technical')

      expect(details['open']).to be_nil
      expect(details.at_css('summary').text.strip).to eq('Detalles técnicos')
      expect(details.css('dt').map { |dt| dt.text.strip }).to eq(['Orden de bytes'])
    end

    it 'shows activity dates in full and in the reader\'s language' do
      allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:events)
        .and_return([{ action: 'User admin uploaded harbor-0001.jpg', timestamp: Time.zone.local(2026, 9, 3).to_i.to_s }])
      get "/concern/file_sets/#{file_set.id}", params: { locale: 'de' }

      expect(doc.at_css('.dc-activity .activity-date time').text).to eq('3. September 2026')
      expect(doc.at_css('.dc-activity th').text).to eq('Benutzeraktivität')
      expect(doc.at_css('relative-time')).to be_nil
    end
  end

  describe 'the collection page' do
    let(:collection) { indexed_collection('Harbor Photographs') }
    let(:doc) { Nokogiri::HTML(response.body) }

    after { FileUtils.rm_rf(Rails.root.join('tmp', 'branding')) }

    def branding_file(role, name)
      path = Rails.root.join('tmp', 'branding', collection.id.to_s, role, name).to_s
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
      path
    end

    it 'puts the badges, title, collection search and meta line on one plate' do
      get "/collections/#{collection.id}"
      plate = doc.at_css('section.dc-collection-banner .dc-collection-plate')

      expect(doc.css('h1').map { |h| h.text.strip }).to eq(['Harbor Photographs'])
      expect(plate.at_css('h1#dc-collection-title').text).to eq('Harbor Photographs')
      expect(plate.css('.dc-collection-badges .dc-badge, .dc-collection-badges .badge').size).to eq(2)
      expect(plate.at_css('.dc-collection-meta').text).to include('0 items')
      expect(plate.at_css('.dc-collection-meta').text).to include('Last updated')
      expect(doc.at_css('.dc-collection-banner')['aria-labelledby']).to eq('dc-collection-title')
    end

    it 'searches within the collection from the plate' do
      get "/collections/#{collection.id}"
      form = doc.at_css('.dc-collection-search form[role="search"]')

      expect(form['action']).to include(collection.id.to_s)
      expect(form.at_css('input#collection_search')['placeholder']).to eq('Search this collection')
      expect(form.at_css('button#collection_submit').text.strip).to eq('Search')
      expect(form.at_css("label[for='collection_search']")).to be_present
    end

    it 'shows a plain band when no banner is uploaded' do
      get "/collections/#{collection.id}"

      expect(doc.at_css('section.dc-collection-banner.dc-collection-banner-plain')['style']).to be_nil
    end

    it 'shows the banner image when its file exists, and a plain band when it is missing' do
      CollectionBrandingInfo.create!(collection_id: collection.id.to_s, role: 'banner', local_path: branding_file('banner', 'harbor.jpg'), filename: 'harbor.jpg')

      get "/collections/#{collection.id}"
      expect(doc.at_css('section.dc-collection-banner')['style']).to include("/branding/#{collection.id}/banner/harbor.jpg")

      FileUtils.rm_rf(Rails.root.join('tmp', 'branding'))
      get "/collections/#{collection.id}"
      expect(Nokogiri::HTML(response.body).at_css('section.dc-collection-banner-plain')).to be_present
    end

    it 'lists the logos whose files exist, linked when they have a URL' do
      CollectionBrandingInfo.create!(collection_id: collection.id.to_s, role: 'logo', local_path: branding_file('logo', 'museum.png'),
                                     filename: 'museum.png', alt_text: 'Harbor Museum', target_url: 'https://example.org')
      CollectionBrandingInfo.create!(collection_id: collection.id.to_s, role: 'logo', local_path: '/nowhere/branding/x/logo/gone.png', filename: 'gone.png')

      get "/collections/#{collection.id}"
      logos = doc.css('.dc-collection-plate .dc-collection-logos li')

      expect(logos.size).to eq(1)
      expect(logos.first.at_css('a[href="https://example.org"] img')['alt']).to eq('Harbor Museum')
    end

    it 'encodes the banner file name so it cannot break out of the style attribute' do
      CollectionBrandingInfo.create!(collection_id: collection.id.to_s, role: 'banner', local_path: branding_file('banner', "harbor's (1).jpg"), filename: 'x.jpg')

      get "/collections/#{collection.id}"

      expect(doc.at_css('section.dc-collection-banner')['style']).to include('harbor%27s%20%281%29.jpg')
    end

    it 'names a linked logo after the collection when it has no alt text' do
      CollectionBrandingInfo.create!(collection_id: collection.id.to_s, role: 'logo', local_path: branding_file('logo', 'museum.png'),
                                     filename: 'museum.png', target_url: 'https://example.org')

      get "/collections/#{collection.id}"

      expect(doc.at_css('.dc-collection-logos a img')['alt']).to eq('Harbor Photographs logo')
    end

    it 'offers the translated homepage toggle that fits whether the collection is featured' do
      get "/collections/#{collection.id}"
      expect(doc.at_css('.dc-collection-actions a[data-behavior="feature"]').text.strip).to eq('Feature on homepage')
      expect(doc.at_css('.dc-collection-actions a[data-behavior="feature"]')['class']).not_to include('collapse')
      expect(doc.at_css('.dc-collection-actions a[data-behavior="unfeature"]')['class']).to include('collapse')

      FeaturedCollection.create!(collection_id: collection.id.to_s)
      get "/collections/#{collection.id}"
      featured = Nokogiri::HTML(response.body)
      expect(featured.at_css('.dc-collection-actions a[data-behavior="unfeature"]').text.strip).to eq('Remove from homepage')
      expect(featured.at_css('.dc-collection-actions a[data-behavior="unfeature"]')['class']).not_to include('collapse')
    end

    it 'offers Copy permalink on its own line under the details line when the feature is on' do
      allow(Flipflop).to receive(:enabled?).and_call_original
      allow(Flipflop).to receive(:enabled?).with(:copy_permalink_button).and_return(true)

      get "/collections/#{collection.id}"

      button = doc.at_css('.dc-collection-meta + p.dc-collection-permalink > button.dc-copy:first-child')
      expect(button['data-dc-copy-text']).to end_with("/collections/#{collection.id}")
      expect(button.next_element).to match('span.dc-copied:last-child')
      expect(doc.at_css('.dc-collection-meta .dc-copy')).to be_nil
      expect(doc.at_css('.dc-collection-badges .dc-copy')).to be_nil
    end

    it 'gives an editor one row of short, translated actions' do
      get "/collections/#{collection.id}"
      row = doc.at_css('section.dc-collection-actions')
      labels = row.css('.dc-collection-actions-inner > .btn:not(.collapse)').map { |b| b.text.strip }

      expect(labels).to start_with('Edit collection', 'Add works')
      expect(labels.last).to eq('Delete collection')
      expect(row.css('h2.sr-only').size).to eq(1)
      expect(row.at_css('a.dc-action-danger')['data-confirm']).to be_present
    end

    it 'shows a visitor no actions' do
      sign_out admin
      get "/collections/#{collection.id}"

      expect(doc.css('.dc-collection-actions-inner .btn')).to be_empty
    end

    it 'shows the details under a section head with ruled rows and no Total items row' do
      described = indexed_with_visibility(
        CollectionResource.new(title: ['Harbor Maps'], description: ['Survey maps of the harbor.'], creator: ['Harbor Museum'],
                               collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s), 'open'
      )
      Hyrax::PermissionTemplate.find_or_create_by!(source_id: described.id.to_s)

      get "/collections/#{described.id}"
      details = doc.at_css('section.dc-collection-details')

      expect(details['aria-labelledby']).to eq('dc-collection-details-heading')
      expect(details.at_css('.dc-section-head h2#dc-collection-details-heading').text).to eq('Collection details')
      expect(details.at_css('.dc-collection-description').text).to include('Survey maps of the harbor.')
      expect(details.css('dl.dc-meta-rows dt').map { |dt| dt.text.strip }).to include('Creator')
      expect(details.css('dl.dc-meta-rows dt').map { |dt| dt.text.strip }).not_to include('Total items')
    end

    describe 'the subcollections and works' do
      let!(:work) do
        indexed_with_visibility(GenericWorkResource.new(title: ['Harbor at dawn'], creator: ['Rau'], member_of_collection_ids: [collection.id]), 'open')
      end

      it 'lists the works with the search page toolbar, rows and pager' do
        get "/collections/#{collection.id}"
        works = doc.at_css('section.dc-collection-works')

        expect(works.at_css('.dc-section-head h2#dc-works-heading').text).to eq('Works in this collection (1)')
        expect(works.at_css('.dc-section-head .dc-toolbar .dc-toolbar-range').text.squish).to eq('1–1 of 1')
        expect(works.at_css('#search-results li.document').text).to include('Harbor at dawn')
        expect(works.css('.dc-view-toggle a .caption').map(&:text)).to include('List', 'Grid')
      end

      it 'keeps the toolbar links on the collection page' do
        get "/collections/#{collection.id}"

        links = doc.css('.dc-collection-works .dc-toolbar .dropdown-item, .dc-collection-works .dc-view-toggle a').map { |a| a['href'] }
        expect(links).not_to be_empty
        expect(links).to all(start_with("/collections/#{collection.id}"))
      end

      it 'brings the reader back to the works after a sort, view, page or search change' do
        get "/collections/#{collection.id}"
        links = doc.css('.dc-collection-works .dc-toolbar .dropdown-item, .dc-collection-works .dc-view-toggle a').map { |a| a['href'] }

        expect(doc.at_css('section#dc-collection-works')).to be_present
        expect(links).to all(end_with('#dc-collection-works'))
        expect(doc.at_css('form.dc-collection-search-form')['action']).to end_with('#dc-collection-works')
      end

      it 'keeps the toolbar links on this site whatever the query string holds' do
        get "/collections/#{collection.id}", params: { host: 'evil.example' }

        links = doc.css('.dc-collection-works .dc-toolbar a, .dc-collection-works .dc-view-toggle a').map { |a| a['href'] }
        expect(links).to all(start_with("/collections/#{collection.id}"))
      end

      it 'shows the works in the Masonry and Slideshow views' do
        get "/collections/#{collection.id}", params: { view: 'masonry' }
        expect(doc.at_css('.dc-collection-works ul.dc-cards-masonry li.dc-card').text).to include('Harbor at dawn')

        get "/collections/#{collection.id}", params: { view: 'slideshow' }
        expect(Nokogiri::HTML(response.body).at_css('.dc-collection-works .documents-slideshow .slideshow-preview-thumbnail')).to be_present
      end

      it 'shows the works as cards in the Grid view' do
        get "/collections/#{collection.id}", params: { view: 'gallery' }

        expect(doc.at_css('.dc-collection-works ul.dc-cards-gallery li.dc-card').text).to include('Harbor at dawn')
      end

      it 'shows subcollections as collection cards' do
        child = indexed_with_visibility(
          Hyrax::PcdmCollection.new(title: ['Harbor surveys'], member_of_collection_ids: [collection.id],
                                    collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s), 'open'
        )
        Hyrax::PermissionTemplate.find_or_create_by!(source_id: child.id.to_s)

        get "/collections/#{collection.id}"
        section = doc.at_css('section.dc-collection-subcollections')

        expect(section.at_css('h2#dc-subcollections-heading').text).to eq('Subcollections (1)')
        expect(section.at_css('li.dc-card .dc-card-link').text).to eq('Harbor surveys')
      end

      it 'keeps the subcollections on any page of works' do
        child = indexed_with_visibility(
          Hyrax::PcdmCollection.new(title: ['Harbor surveys'], member_of_collection_ids: [collection.id],
                                    collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s), 'open'
        )
        Hyrax::PermissionTemplate.find_or_create_by!(source_id: child.id.to_s)

        get "/collections/#{collection.id}", params: { page: 2 }

        expect(doc.at_css('section.dc-collection-subcollections li.dc-card .dc-card-link').text).to eq('Harbor surveys')
      end

      it 'says so when a search within the collection finds nothing' do
        get "/collections/#{collection.id}", params: { cq: 'zeppelin' }
        works = doc.at_css('section.dc-collection-works')

        expect(works.at_css('h2').text).to eq('Search results (0)')
        expect(works.at_css('.dc-collection-no-results').text).to include('zeppelin')
      end
    end

    it 'links each detail the way the flexible metadata profile says' do
      skip 'needs flexible metadata' unless Hyrax.config.flexible?
      profiled = indexed_with_visibility(
        CollectionResource.new(title: ['Harbor Records'], creator: ['Harbor Museum'], resource_type: ['Map'],
                               license: ['https://creativecommons.org/licenses/by/4.0/'],
                               collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s), 'open'
      )
      Hyrax::PermissionTemplate.find_or_create_by!(source_id: profiled.id.to_s)

      get "/collections/#{profiled.id}", params: { sort: 'title_ssi asc' }
      rows = doc.css('dl.dc-meta-rows > div').to_h { |row| [row.at_css('dt').text.strip, row.at_css('dd')] }
      license = rows['License'].css('a').find { |a| a['href'].start_with?('https://creativecommons.org') }

      expect(rows['Creator'].at_css('a')['href']).to include('search_field=creator')
      expect(CGI.unescape(rows.find { |term, _| term.casecmp?('Resource type') }.last.at_css('a')['href'])).to include('f[resource_type_sim][]=Map')
      expect([license['target'], license['rel']]).to eq(['_blank', 'noopener noreferrer'])
      expect(doc.css('dl.dc-meta-rows a').map { |a| a['href'] }).to all(satisfy { |href| !href.include?('sort=') })
    end

    it 'translates the plate in another language' do
      get "/collections/#{collection.id}", params: { locale: 'de' }

      expect(response.body).not_to include('translation_missing')
      expect(doc.at_css('input#collection_search')['placeholder']).to eq('In dieser Sammlung suchen')
      expect(doc.at_css('.dc-collection-meta').text).to include('0 Objekte')
    end
  end
end
