# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Work show actions', type: :feature, clean: true do
  let(:admin) { create(:admin) }

  # Hyku runs Hyrax::ValkyrieLazyMigration, so a GenericWork (ActiveFedora) and a
  # GenericWorkResource (Valkyrie) are shown through the SAME /concern/generic_works/:id
  # route. We run the same show-page expectations against both backings; each backing
  # context provides `make_work` / `make_work_with_file` returning a persisted work.
  shared_examples 'the work show page' do
    let!(:work) do
      make_work(title: ['Coastal Erosion Survey 2019'], keyword: ['shoreline monitoring'], visibility: 'open')
    end

    describe 'as an administrator' do
      before { login_as admin }

      it 'shows the Edit, Delete, Add to Collection, Feature and Attach Child controls' do
        visit "/concern/generic_works/#{work.id}"

        # Edit/Delete are link_to and Add to Collection is a button_tag in
        # app/views/hyrax/base/_show_actions.html.erb.
        expect(page).to have_link('Edit')
        expect(page).to have_link('Delete')
        expect(page).to have_button('Add to collection')
        # Feature renders for a Public work (work_featurable? -> solr public?).
        expect(page).to have_link('Feature')
        # _attach_child_control.html.erb renders "Attach #{human_readable_type}" per
        # valid child concern (Work/Image) under an "Attach Child" dropdown-toggle button.
        # rack_test ignores the collapsed dropdown CSS, so its items are findable.
        expect(page).to have_button('Attach Child')
        expect(page).to have_link('Attach Work')
        expect(page).to have_link('Attach Image')
      end

      it 'hides the Feature action for a non-public work' do
        private_work = make_work(title: ['Private feature test'], visibility: 'restricted')

        visit "/concern/generic_works/#{private_work.id}"

        expect(page).to have_content('Private feature test')
        # For a Public work the Feature link renders without the `collapse` class; for a
        # non-public work it must never be an actionable, non-collapsed control.
        expect(page).not_to have_css('a.btn:not(.collapse)', text: 'Feature')
      end

      it 'lists each attached file in the items table with its details and action menu' do
        work_with_file = make_work_with_file(title: ['Work with attached items'], visibility: 'open')

        visit "/concern/generic_works/#{work_with_file.id}"

        # Each row (hyrax/base/_member) shows thumbnail, title, date uploaded, visibility,
        # and a per-file actions dropdown (hyrax/file_sets/_actions) for an editor.
        within(find('tr', text: 'Attached file item')) do
          expect(page).to have_css('td.thumbnail')
          expect(page).to have_link('Attached file item')
          expect(page).to have_css('td.attribute-date_uploaded')
          expect(page).to have_css('.badge', text: 'Private')
          expect(page).to have_button('Select an action')
          expect(page).to have_link('Edit')
          expect(page).to have_link('Versions')
          expect(page).to have_link('Delete')
          expect(page).to have_link('Download')
        end
      end
    end

    describe 'as an anonymous public user' do
      # No login: exercise the genuinely public read-only view of a Public work.
      it 'shows the title, visibility, metadata, relationships and citation affordances' do
        visit "/concern/generic_works/#{work.id}"

        # Title + permission badge ("Public" for an open work).
        expect(page).to have_content('Coastal Erosion Survey 2019')
        expect(page).to have_content('Public')
        # Descriptive metadata list.
        expect(page).to have_css('dl')
        expect(page).to have_content('shoreline monitoring')
        # Relations card (its title renders as "Relations").
        expect(page).to have_content('Relations')
        # Citations: the COinS span (read by Zotero/Mendeley) lives in _show_actions.html.erb.
        expect(page).to have_content('Citation')
        expect(page).to have_css('span.Z3988', visible: :all)
      end

      it 'offers EndNote, Zotero, and Mendeley citation downloads' do
        visit "/concern/generic_works/#{work.id}"

        # hyrax/base/_citations: a "Citation" dropdown (Hyku relabels its header) whose
        # items are EndNote, Zotero and Mendeley.
        within('.citations') do
          expect(page).to have_link('EndNote')
          expect(page).to have_link('Zotero')
          expect(page).to have_link('Mendeley')
        end
      end

      it 'downloads an EndNote citation of the work from the Citation menu' do
        visit "/concern/generic_works/#{work.id}"

        within('.citations') { click_link 'EndNote' }

        # WorksControllerBehavior#respond_to_endnote sends the solr document as a Refer file.
        expect(page.response_headers['Content-Type']).to include('application/x-endnote-refer')
        expect(page.response_headers['Content-Disposition']).to include('.endnote')
        expect(page.body).to include('%T Coastal Erosion Survey 2019')
      end

      it 'does not show administrative action controls' do
        visit "/concern/generic_works/#{work.id}"

        expect(page).not_to have_link('Edit')
        expect(page).not_to have_link('Delete')
        expect(page).not_to have_link('Feature')
        expect(page).not_to have_button('Attach Child')
        expect(page).not_to have_button('Add to collection')
      end
    end
  end

  context 'with an ActiveFedora-backed work' do
    def make_work(title:, visibility: 'open', **attrs)
      create(:generic_work, user: admin, title: title, visibility: visibility, **attrs)
    end

    def make_work_with_file(title:, visibility: 'open')
      # Remove this comment and the `pending` call to re-enable this test when issue #3418 is fixed.
      # KNOWN APPLICATION ISSUE (flexible metadata only): saving a legacy AF file set fails
      # (Hyrax's AF FileSetIndexer reads `transcript_ids`, which the AF ::FileSet lacks when
      # flexible metadata is on). Fix goes in Hyrax (samvera/hyrax): Hyrax::FileSetIndexer
      # (guard the `transcript_ids` call). Pending keeps this running and fails once fixed.
      pending("ActiveFedora FileSets cannot be indexed with flexible metadata on (undefined method `transcript_ids')") if Hyrax.config.flexible?
      make_work(title: title, visibility: visibility).tap do |work|
        # Mirrors spec/factories/images.rb (:image_with_one_file).
        work.ordered_members << create(:file_set, user: admin, title: ['Attached file item'])
        work.save!
      end
    end

    it_behaves_like 'the work show page'
  end

  context 'with a Valkyrie-backed work' do
    def make_work(title:, visibility: 'open', **attrs)
      FactoryBot.valkyrie_create(:generic_work_resource,
                                 depositor: admin.user_key,
                                 title: title,
                                 visibility_setting: visibility,
                                 **attrs)
    end

    def make_work_with_file(title:, visibility: 'open')
      file_set = FactoryBot.valkyrie_create(:hyrax_file_set, title: ['Attached file item'])
      make_work(title: title, visibility: visibility, member_ids: [file_set.id])
    end

    it_behaves_like 'the work show page'
  end

  # Documented gaps that are independent of the persistence backing (gem-only partials
  # or theme-specific markup). Kept as single skips rather than duplicated per backing.
  # IIIF media viewer: shown when the work's representative is a viewable image
  # (WorkShowPresenter#iiif_viewer?, with config.iiif_image_server on). A real PNG is
  # attached with an explicit MIME type, so no FITS characterization is needed; the
  # viewer markup is server-rendered, so no image tiles have to load.
  it 'renders the IIIF media viewer for a work whose representative is an image' do
    image_file_set = FactoryBot.valkyrie_create(:hyrax_file_set, :public, title: ['Image file'])
    Hyrax::ValkyrieUpload.file(filename: 'world.png', file_set: image_file_set,
                               io: File.open(Rails.root.join('spec', "fixtures", "images", "world.png")),
                               mime_type: 'image/png')
    Hyrax.index_adapter.save(resource: Hyrax.query_service.find_by(id: image_file_set.id))
    work = FactoryBot.valkyrie_create(:generic_work_resource, :public,
                                      title: ['Image work'],
                                      member_ids: [image_file_set.id],
                                      representative_id: image_file_set.id,
                                      thumbnail_id: image_file_set.id)

    visit "/concern/generic_works/#{work.id}"

    expect(page).to have_css(".viewer-wrapper iframe[src*='uv/uv.html'][src*='#{work.id}/manifest']")
  end

  # hyrax/base/_work_title.erb (Hyku override) renders presenter.workflow.badge next to the
  # permission badge. A work deposited into a mediated-workflow admin set starts in
  # `pending_review`, so its badge reads "Pending review" (state.humanize; no translation).
  it 'shows the workflow status badge for a work in a review workflow' do
    # Creating a workflow admin set grants workflow roles to the admin group.
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('one_step_mediated_deposit')
    admin_set = Hyrax::AdminSetCreateService.call!(admin_set: AdminSet.new(title: ['Badge Admin Set']),
                                                   creating_user: nil)
    work = FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set,
                                      admin_set:, depositor: admin.user_key,
                                      title: ['Workflow badge work'], visibility_setting: 'open')
    expect(Sipity::Entity(work).workflow_state.name).to eq('pending_review')
    login_as admin

    visit "/concern/generic_works/#{work.id}"

    within('.title-with-badges') do
      expect(page).to have_css('h1', text: 'Workflow badge work')
      expect(page).to have_css('.badge', text: 'Public')
      expect(page).to have_css('span.state.state-pending_review.badge', text: 'Pending review')
    end
  end

  it 'shows no workflow status badge for a work outside any workflow' do
    work = FactoryBot.valkyrie_create(:generic_work_resource, :public, title: ['No workflow work'])

    visit "/concern/generic_works/#{work.id}"

    within('.title-with-badges') do
      expect(page).to have_css('.badge', text: 'Public')
      expect(page).not_to have_css('span.state')
    end
  end

  # Relations card: hyrax/base/_relationships_parent_rows lists parent collections and the
  # Hyku override of hyrax/base/_relationships adds "Part of:" links to parent works.
  it 'links the parent collection and parent work in the Relations card' do
    collection = FactoryBot.valkyrie_create(:hyku_collection, :public, title: ['Relations parent collection'])
    child = FactoryBot.valkyrie_create(:generic_work_resource, :public,
                                       title: ['Relations child work'],
                                       member_of_collection_ids: [collection.id])
    parent = FactoryBot.valkyrie_create(:generic_work_resource, :public,
                                        title: ['Relations parent work'], member_ids: [child.id])

    visit "/concern/generic_works/#{child.id}"

    relations_card = "//div[contains(concat(' ', @class, ' '), ' card ')][.//h2[normalize-space()='Relations']]"
    within(:xpath, relations_card) do
      collection_link = find_link('Relations parent collection')
      expect(collection_link[:href]).to include("/collections/#{collection.id}")
      expect(page).to have_content('Part of:')
      parent_link = find_link('Relations parent work')
      expect(parent_link[:href]).to include("/concern/generic_works/#{parent.id}")
    end

    click_link 'Relations parent work'
    expect(page).to have_css('h1', text: 'Relations parent work')
  end

  # (No setup here: a `skip` inside the example still runs let!/before hooks first.)
  describe 'documented gaps' do
    # Remove this comment, replace the `skip` with a real test, and re-enable it when issue #3417
    # is fixed. Fix goes in: app/views/hyrax/base/show.html.erb (render the
    # hyrax/base/_social_media partial, as file sets already do).
    it 'links to social-media share icons for the work' do
      skip("Not implemented for works in Hyku: app/views/hyrax/base/show.html.erb renders no " \
           'social-media share partial, and no Hyku view renders work share links (file sets ' \
           'do, via hyrax/base/_social_media). Gap between the test plan and the application.')
    end
  end
end
