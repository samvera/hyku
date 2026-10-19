# frozen_string_literal: true

require 'rails_helper'

# Only the edit-then-delete example needs a browser (the confirm dialog, and the HTML5
# required-field check that blocks Save); the rest are server-rendered and run under rack_test.
RSpec.describe 'FileSet Show and Actions', type: :feature, clean: true do
  let(:admin_user) { create(:admin) }

  # A FileSet is a child member of a parent work, and the show page's presenter
  # resolves `parent` (see hyrax/file_sets/show.html.erb, which references
  # `@presenter.parent.id`), so an orphaned file set can fail to render. Each backing
  # context below supplies a PUBLIC `file_set` attached to a PUBLIC inline parent
  # work, so both an admin and an anonymous visitor can view it. We run the same
  # expectations against an ActiveFedora-backed and a Valkyrie-backed file set.

  # Content any viewer can see on a public file set. Consolidated into a single
  # example to avoid reloading this (slow, JS) page once per assertion.
  shared_examples 'the public FileSet show page' do
    it 'shows the title, visibility, media, details, activity and social links' do
      visit "/concern/file_sets/#{file_set.id}"

      # Title + visibility badge (public => "Public").
      expect(page).to have_selector('h1', text: 'Test FileSet')
      expect(page).to have_css('.badge', text: 'Public')

      # Media display + download link. No binary is ingested, so the default media
      # partial renders; its download control has id="file_download" and the label
      # resolves to hyrax.file_set.show.download ("Download the file").
      expect(page).to have_content('No preview available')
      expect(page).to have_css('a#file_download')
      expect(page).to have_link('Download the file')

      # File Details table (hyrax/file_sets/_show_details).
      expect(page).to have_selector('h2', text: 'File Details')
      # Two dl.file-show-details render (File Details and Metadata); scope to the first.
      within(find('h2', text: 'File Details').find(:xpath, 'following-sibling::dl[1]')) do
        expect(page).to have_css('dt', text: 'Depositor')
        expect(page).to have_css('dt', text: 'Date Uploaded')
      end

      # User Activity table (hyrax/users/_activity_log renders unconditionally).
      expect(page).to have_selector('table#activity')
      expect(page).to have_content('No user activity')

      # Social media share links (hyrax/base/_social_media). Matched on aria-label
      # rather than domain: the Twitter link now points at x.com/intent.
      expect(page).to have_css('.social-media')
      expect(page).to have_css("a[aria-label='Share on Facebook']")
      expect(page).to have_css("a[aria-label='Share on Twitter']")
      expect(page).to have_css("a[aria-label='Share on Tumblr']")
    end
  end

  # Admin-only affordances: Edit / Delete / Single-Use Link. In the show view the
  # single-use links partial renders only `if @presenter.editor?`.
  shared_examples 'the admin FileSet controls' do
    it 'shows the Edit, Delete, and Single-Use Link controls' do
      visit "/concern/file_sets/#{file_set.id}"

      expect(page).to have_link('Edit This File')
      expect(page).to have_link('Delete This File')
      expect(page).to have_selector('h3', text: 'Single-Use Links')
      # Hyku overrides hyrax.single_use_links.button to "Single-Use Link to File".
      expect(page).to have_link('Single-Use Link to File')
    end

    # The button POSTs via AJAX (hyrax/single_use_links_manager.js) and then reloads the
    # table body from the generated-links endpoint.
    it 'generates a single-use link that appears in the Single-Use Links table', js: true do
      visit "/concern/file_sets/#{file_set.id}"
      expect(page).to have_css('table.single-use-links', text: 'No links have been generated')

      click_link 'Single-Use Link to File'

      expect(page).to have_css('table.single-use-links tr', text: /Link \S+ expires/, count: 1)
      expect(page).to have_css('table.single-use-links .delete-single-use-link', count: 1)
      expect(SingleUseLink.where(item_id: file_set.id.to_s).count).to eq(1)
      link = SingleUseLink.find_by(item_id: file_set.id.to_s)
      expect(page).to have_css("button.copy-single-use-link[data-clipboard-text*='#{link.download_key}']")
    end

    it 'edits the file title and then deletes the file', js: true do
      visit "/concern/file_sets/#{file_set.id}"

      click_link 'Edit This File'
      # Target the first title input by id (a blank trailing input follows it). Creator
      # is required on the file set form; the factory file set has none, and the browser
      # will not submit the form until it is filled.
      find('#file_set_title').fill_in(with: 'Updated FileSet')
      find('#file_set_creator').fill_in(with: 'File Creator')
      # The Permissions tab has its own Save; submit the Descriptions form.
      within("form#edit_file_set_#{file_set.id}") { click_button 'Save' }
      expect(page).to have_content('has been updated')
      expect(page).to have_content('Updated FileSet')

      # The delete link carries data-confirm ("Delete this File?").
      accept_confirm { click_link 'Delete This File' }
      expect(page).to have_current_path(%r{/concern/generic_works/#{parent_work.id}})
      expect(page).not_to have_content('Updated FileSet')
      expect(Hyrax.query_service.find_many_by_ids(ids: [file_set.id]).to_a).to be_empty
    end
  end

  # An anonymous visitor can view a public file set but must not see admin controls.
  shared_examples 'no admin FileSet controls for anonymous visitors' do
    it 'hides the Edit, Delete, and Single-Use Link controls' do
      visit "/concern/file_sets/#{file_set.id}"

      expect(page).to have_selector('h1', text: 'Test FileSet') # the page did render
      expect(page).not_to have_link('Edit This File')
      expect(page).not_to have_link('Delete This File')
      expect(page).not_to have_link('Single-Use Link to File')
    end
  end

  # Runs the admin and anonymous viewpoints against whatever public file set the
  # including backing context provides.
  shared_examples 'a public file set viewable by admins and anonymous users' do
    context 'as an admin' do
      before { login_as admin_user }

      it_behaves_like 'the public FileSet show page'
      it_behaves_like 'the admin FileSet controls'
    end

    context 'as an anonymous user' do
      it_behaves_like 'the public FileSet show page'
      it_behaves_like 'no admin FileSet controls for anonymous visitors'
    end
  end

  # An image file set renders its thumbnail and a "Download image" link (the plan's
  # "Download Image link") via hyrax/file_sets/media_display/_image. A real PNG is attached
  # with an explicit MIME type so no FITS characterization is needed. Derivatives are not
  # generated in tests, so the thumbnail <img> points at the default placeholder.
  it 'shows the thumbnail and Download image link for an image file' do
    image_file_set = FactoryBot.valkyrie_create(:hyrax_file_set, :public, title: ['Image FileSet'])
    Hyrax::ValkyrieUpload.file(filename: 'world.png', file_set: image_file_set,
                               io: File.open(Rails.root.join('spec', "fixtures", "images", "world.png")),
                               mime_type: 'image/png')
    Hyrax.index_adapter.save(resource: Hyrax.query_service.find_by(id: image_file_set.id))
    FactoryBot.valkyrie_create(:generic_work_resource, :public,
                               title: ['Image Parent'], member_ids: [image_file_set.id])

    visit "/concern/file_sets/#{image_file_set.id}"

    expect(page).to have_css('img.representative-media')
    expect(page).to have_link('Download image')
  end

  context 'with an ActiveFedora-backed file set' do
    # KNOWN APPLICATION ISSUE (flexible metadata only): Hyrax's ActiveFedora FileSetIndexer
    # always reads `transcript_ids`, but with flexible metadata on (HYRAX_DISABLE_INCLUDE_METADATA)
    # the AF ::FileSet never gets that property, so saving a legacy AF file set raises
    # NoMethodError. `pending` keeps these running and fails loudly once it is fixed.
    # (Declared before the let! below so it is marked pending before the setup raises.)
    # Remove this comment and the `pending` call to re-enable these tests when issue #xxxx is fixed.
    # KNOWN APPLICATION ISSUE (flexible metadata only): saving a legacy AF FileSet fails because
    # Hyrax's AF FileSetIndexer calls `transcript_ids`, which ::FileSet lacks when flexible
    # metadata is on. Fix goes in Hyrax (samvera/hyrax): Hyrax::FileSetIndexer (guard the
    # `transcript_ids` call).
    before do
      if Hyrax.config.flexible?
        pending('ActiveFedora FileSets cannot be indexed with flexible metadata on ' \
                "(undefined method `transcript_ids' for FileSet)")
      end
    end

    let(:file_set) { create(:file_set, :public, title: ['Test FileSet'], user: admin_user) }
    # Attach to an inline public parent work (mirrors work_show_actions_spec.rb).
    let!(:parent_work) do
      create(:generic_work, :public, user: admin_user, title: ['Parent Work']).tap do |work|
        work.ordered_members << file_set
        work.save!
      end
    end

    it_behaves_like 'a public file set viewable by admins and anonymous users'
  end

  context 'with a Valkyrie-backed file set' do
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :public, title: ['Test FileSet']) }
    # Attach via member_ids on a public Valkyrie GenericWorkResource and index it, so
    # the show page can resolve the parent (mirrors hyku_indexing_spec.rb).
    let!(:parent_work) do
      FactoryBot.valkyrie_create(:generic_work_resource, :public, title: ['Parent Work'], member_ids: [file_set.id])
    end

    it_behaves_like 'a public file set viewable by admins and anonymous users'
  end
end
