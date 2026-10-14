# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Work show actions', type: :feature, clean: true do
  let(:admin) { create(:admin) }
  let!(:work) { create(:generic_work, user: admin, title: ['Work actions test'], visibility: 'open') }

  before do
    login_as admin
  end

  it 'shows work metadata, citations, relationships, and item actions' do
    visit hyrax_generic_work_path(work)

    expect(page).to have_content('Work actions test')
    expect(page).to have_content('Citation')
    expect(page).to have_content('Edit')
    expect(page).to have_content('Delete')
    expect(page).to have_content('Add to Collection')
  end

  it 'offers public-work feature and child-work actions to an administrator' do
    visit hyrax_generic_work_path(work)

    expect(page).to have_link('Feature')
    expect(page).to have_link('Attach Child')
  end

  # ---------------------------------------------------------------------------
  # Manual Test Plan -> "Work Show Page" -> "As a user"
  #
  # The action buttons in app/views/hyrax/base/_show_actions.html.erb are all
  # gated on the presenter's ability (editor?/work_featurable?/show_deposit_for?),
  # so a logged-out visitor to a Public work sees the read-only display only.
  # ---------------------------------------------------------------------------
  describe 'as an anonymous public user' do
    # Drop the admin session established by the outer `before` so we exercise the
    # genuinely public view. `logout(:user)` is the in-repo pattern (see
    # spec/features/transfers_and_proxies_spec.rb).
    before { logout(:user) }

    it 'shows the work title with its public visibility badge' do
      visit hyrax_generic_work_path(work)

      # Title from app/views/hyrax/base/_work_title.erb, followed by the
      # permission_badge, which reads "Public" for an open work (grounded by
      # spec/features/batch_work_creation_spec.rb, which asserts have_content('Public')).
      expect(page).to have_content('Work actions test')
      expect(page).to have_content('Public')
    end

    it 'shows a descriptive metadata list containing the work fields' do
      described_work = create(:generic_work,
                              user: admin,
                              title: ['Metadata list work'],
                              keyword: ['grounded-metadata-value'],
                              visibility: 'open')

      visit hyrax_generic_work_path(described_work)

      # The metadata card in show.html.erb renders `render 'metadata'` into a
      # definition list (see app/views/hyrax/base/_relationships.html.erb which
      # shares the <dl class="work-show"> structure).
      expect(page).to have_css('dl')
      expect(page).to have_content('grounded-metadata-value')
    end

    it 'shows the Relationships section' do
      visit hyrax_generic_work_path(work)

      # Heading text from config/locales/en.yml (hyrax.base.show.relationships: "Relationships")
      # rendered by the relationships card in app/views/hyrax/base/show.html.erb.
      expect(page).to have_content('Relationships')
    end

    it 'exposes citation and export affordances' do
      visit hyrax_generic_work_path(work)

      # A fileless work falls into the no-viewer branch of show.html.erb, which
      # renders the citations partial. The COinS span lives in _show_actions.html.erb
      # (line 46) and is what Zotero/Mendeley browser connectors read to import a
      # citation.
      expect(page).to have_content('Citation')
      expect(page).to have_css('span.Z3988', visible: :all)
    end

    it 'names the EndNote/Zotero/Mendeley citation download options' do
      skip('The default Citations dropdown and its EndNote/Zotero/Mendeley item ' \
           'labels are rendered by the Hyrax gem partial hyrax/base/_citations.html.erb, ' \
           'which is installed only inside the Docker test image and could not be read ' \
           'from disk in this environment. Verify the exact link labels in a real run.')

      visit hyrax_generic_work_path(work)
      expect(page).to have_link('EndNote')
      expect(page).to have_link('Zotero')
      expect(page).to have_link('Mendeley')
    end

    it 'renders a IIIF media viewer for a work with a viewable representative image' do
      skip('The IIIF/Universal Viewer requires a representative image FileSet with a ' \
           'derivative served by a configured IIIF image server (see ' \
           'app/presenters/hyku/media_viewer_behavior.rb#iiif_viewer? and the tenant-level ' \
           'checks it delegates to). That pipeline is not reproducible in a headless feature ' \
           'spec without image derivatives; exercise it against a real tenant with js: true.')

      # Intended assertion once a representative image + image server are present:
      #   visit hyrax_generic_work_path(work_with_image)
      #   expect(page).to have_css('.viewer, #uv, .universal-viewer-container')
    end

    it 'links to social-media share icons for the work' do
      skip("Hyku's overridden app/views/hyrax/base/show.html.erb does not render a " \
           'social-media share partial on the default work show page (no _social_media ' \
           'partial exists under app/views). Social sharing appears only in specific ' \
           'themes, so there is no selector to assert on the default theme.')
    end

    it 'does not show administrative action buttons' do
      visit hyrax_generic_work_path(work)

      expect(page).not_to have_link('Edit')
      expect(page).not_to have_link('Delete')
      expect(page).not_to have_link('Feature')
      expect(page).not_to have_link('Attach Child')
      expect(page).not_to have_button('Add to Collection')
    end
  end

  # ---------------------------------------------------------------------------
  # Manual Test Plan -> "Work Show Page" -> "As a user" -> Items table
  # ---------------------------------------------------------------------------
  describe 'the Items/files table' do
    let!(:work_with_file) do
      w = create(:generic_work, user: admin, title: ['Work with attached items'], visibility: 'open')
      # Mirrors the attach pattern used by spec/factories/images.rb (:image_with_one_file).
      w.ordered_members << create(:file_set, user: admin, title: ['Attached file item'])
      w.save!
      w
    end

    it 'lists each attached file in the items section' do
      visit hyrax_generic_work_path(work_with_file)

      # The Items card (show.html.erb, `render 'items'`) lists the work's members
      # via presenter.list_of_item_ids_to_display; the attached FileSet's title
      # should surface as a row.
      expect(page).to have_content('Attached file item')
    end

    it 'offers a per-file "Select an action" menu with Edit, Versions, Delete, and Download' do
      skip('The per-file action dropdown ("Select an action" with Edit/Versions/Delete/Download) ' \
           'is rendered by the Hyrax gem partial hyrax/base/_member.html.erb and its labels come ' \
           'from the gem locale, neither of which was readable from disk in this environment ' \
           '(the gem lives only in the Docker image). Verify the menu items in a real run.')

      # Intended assertion once the gem markup/labels are confirmed:
      #   visit hyrax_generic_work_path(work_with_file)
      #   expect(page).to have_content('Select an action')
      #   expect(page).to have_link('Edit')
      #   expect(page).to have_link('Versions')
      #   expect(page).to have_link('Delete')
      #   expect(page).to have_link('Download')
    end
  end

  # ---------------------------------------------------------------------------
  # Manual Test Plan -> "Work Show Page" -> "As an admin"
  # ---------------------------------------------------------------------------
  describe 'as an administrator' do
    it 'shows the Edit, Delete, and Add to Collection actions' do
      visit hyrax_generic_work_path(work)

      # Edit/Delete are link_to and Add to Collection is a button_tag in
      # app/views/hyrax/base/_show_actions.html.erb.
      expect(page).to have_link('Edit')
      expect(page).to have_link('Delete')
      expect(page).to have_button('Add to Collection')
    end

    it 'offers Attach Work and Attach Image options in the Attach Child menu' do
      visit hyrax_generic_work_path(work)

      # _attach_child_control.html.erb renders "Attach #{concern.human_readable_type}"
      # for each valid child concern. human_readable_type resolves via
      # config/locales/en.yml (activefedora.models.generic_work: "Work", image: "Image").
      # enable_guided_deposit defaults to false (config/features.rb), so the per-concern
      # dropdown (not the single wizard link) is rendered. rack_test ignores the
      # collapsed dropdown's CSS, so the items are findable without js.
      expect(page).to have_link('Attach Work')
      expect(page).to have_link('Attach Image')
    end

    it 'hides the Feature action for a non-public work' do
      private_work = create(:generic_work, user: admin, title: ['Private feature test'], visibility: 'restricted')

      visit hyrax_generic_work_path(private_work)

      expect(page).to have_content('Private feature test')
      # For a Public work the Feature link renders without the `collapse` class
      # (see _show_actions.html.erb display_feature_link? branch); for a non-public
      # work it must never be an actionable, non-collapsed control.
      expect(page).not_to have_css('a.btn:not(.collapse)', text: 'Feature')
    end
  end
end


# ## Work Show Page
# [Back to TOC](#table-of-contents)

# ![image16](https://github.com/samvera/hyku/assets/19597776/f1e0d1ff-66b3-45ad-8965-9ef578b7b32b)

# ### As a user:

# - [ ] I can see the title of the work (as well as its visibility, deposited status, etc)
# - [ ] I can see a IIIF media viewer
# - [ ] I can see any relationships the work may have
# - [ ] I can see a list of metadata specific to the work
# - [ ] I can click on the social media icons to share the work on various social media platforms
# - [ ] I can select a Citation to download from the Citations dropdown menu (EndNote, Zotero, Mendeley)
# - [ ] I can see an Items table containing all the files associated with the work
#   - [ ] I can see basic information for each item in the table (thumbnail, title, date uploaded, visibility, actions)
#   - [ ] I can select an action from the Select an action dropdown menu
#     - [ ] Edit
#     - [ ] Versions
#     - [ ] Delete
#     - [ ] Download

# ### As an admin:

# - [ ] I can also see buttons with actions related to the individual work:
#   - [ ] Edit
#   - [ ] Delete
#   - [ ] Attach Child
#     - [ ] Attach Work
#     - [ ] Attach Image
#   - [ ] Add to Collection
#   - [ ] Feature (only if the work is set to Public visibility)