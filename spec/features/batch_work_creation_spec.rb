# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch Work Creation', type: :feature, js: true, clean: true do
  let(:user) { create(:user, roles: [:work_depositor]) }
  let!(:collection) { create(:collection, user:, title: ['Batch Target Collection']) }
  let!(:sharing_group) { create(:group, name: 'batch_sharing_group', humanized_name: 'Batch Sharing Group') }
  let(:admin_set) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

  before do
    # Default groups may already exist; create them idempotently.
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    admin_set
    Site.update(institution_name: 'Test Institution')
    # Batch upload is gated behind this Flipflop feature.
    allow(Flipflop).to receive(:batch_upload?).and_return(true)
    login_as user, scope: :user
  end

  # Manual test plan: "Dashboard Works New by Batch Page" — sidebar requirements,
  # visibility options, and the Files, Descriptions, Relationships, Sharing tabs.
  it 'shows the batch requirements, visibility options, and all deposit tabs' do
    visit '/batch_uploads/new?payload_concern=GenericWork'
    expect(page).to have_content('Add New Works by Batch')

    # Sidebar: requirements for creating the batch work
    expect(page).to have_content('Requirements')
    expect(page).to have_content('Describe your work')
    expect(page).to have_content('Add files')
    expect(page).to have_content('Check deposit agreement')

    # Sidebar: visibility options. "Institution" shows the site's institution name.
    expect(page).to have_css("input[type='radio'][value='open']")
    expect(page).to have_css("input[type='radio'][value='authenticated']")
    expect(page).to have_css("input[type='radio'][value='embargo']")
    expect(page).to have_css("input[type='radio'][value='lease']")
    expect(page).to have_css("input[type='radio'][value='restricted']")
    expect(page).to have_content('Public')
    expect(page).to have_content('Institution')
    expect(page).to have_content('Test Institution')
    expect(page).to have_content('Embargo')
    expect(page).to have_content('Lease')
    expect(page).to have_content('Private')

    # Files tab
    click_link 'Files'
    expect(page).to have_content('Add files')
    expect(page).to have_content('Add folder')

    # Descriptions tab: Creator is the only primary field (batch works get their
    # title from the filename). Keyword and Rights Statement live in the collapsed
    # "Additional fields" section and only appear once it is expanded.
    click_link 'Descriptions'
    expect(page).to have_field('Creator')
    expect(page).to have_selector(:link_or_button, 'Additional fields')
    click_on 'Additional fields'
    expect(page).to have_field('Keyword')
    expect(page).to have_select('Rights Statement')

    # Relationships tab: Administrative Set and collection selection. The collection
    # picker's native <select> is hidden behind its select2 widget, so visible: :all.
    click_link 'Relationships'
    expect(page).to have_select('Administrative Set')
    expect(page).to have_css("select[name='member_of_collection_ids']", visible: :all)

    # Sharing tab
    click_link 'Sharing'
    expect(page).to have_content('Add Sharing')
    expect(page).to have_css('fieldset.permission-add-group')
    expect(page).to have_css('fieldset.permission-add-user')
  end

  # A completed form (file, required metadata, admin set, agreement) is accepted
  # and shows the background-processing confirmation. Works are created
  # asynchronously, so this asserts the flash rather than a work count.
  it 'accepts the batch for processing when the form is completed and saved' do
    visit '/batch_uploads/new?payload_concern=GenericWork'

    click_link 'Files'
    within('div#add-files') do
      attach_file('files[]', File.join(file_fixture_path, 'hyrax', 'image.jp2'), visible: false)
    end
    # A Delete control appears once the upload finishes; wait for it before saving.
    expect(page).to have_selector(:link_or_button, 'Delete')

    click_link 'Descriptions'
    fill_in 'Creator', with: 'Batch Creator'
    # Keyword and Rights Statement are in the collapsed "Additional fields" section.
    click_on 'Additional fields'
    fill_in 'Keyword', with: 'batch-test'
    select 'In Copyright', from: 'Rights Statement'

    click_link 'Relationships'
    select admin_set.title.first, from: 'Administrative Set'

    # Choosing Public expands the publishing warning, confirming the selection registered.
    find("input[type='radio'][value='open']").click
    expect(page).to have_content('making something visible to the world')

    find('#agreement').click
    click_button('with_files_submit')

    expect(page).to have_content('being processed')
  end

  # Manual test plan: "I can set my created works' visibility". One visibility
  # chosen in the batch must apply to every work it produces. Runs the real create
  # path (controller -> BatchCreateJob -> CreateWorkJob) inline via a direct
  # request. type: :request needs an explicit singletenant (feature specs get it
  # implicitly) to keep routing working.
  context 'setting the batch visibility', type: :request, singletenant: true do
    let(:permission_template) do
      Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set.id.to_s)
    end

    before do
      # The actor stack needs an active workflow and deposit access to persist works.
      Sipity::Workflow.find_or_create_by!(name: 'batch-test-workflow', permission_template:) do |workflow|
        workflow.active = true
      end.tap { |wf| Sipity::WorkflowAction.find_or_create_by!(name: 'submit', workflow: wf) }
      Hyrax::PermissionTemplateAccess.find_or_create_by!(
        permission_template_id: permission_template.id,
        agent_type: 'user',
        agent_id: user.user_key,
        access: 'deposit'
      )
    end

    def batch_uploaded_file
      Hyrax::UploadedFile.create(
        user:,
        file: File.open(File.join(file_fixture_path, 'hyrax', 'image.jp2'))
      )
    end

    it 'applies the chosen visibility to every work created by the batch' do
      first_file = batch_uploaded_file
      second_file = batch_uploaded_file

      # Run only the create jobs inline; leave downstream jobs enqueued.
      perform_enqueued_jobs(only: [BatchCreateJob, CreateWorkJob]) do
        post hyrax.batch_uploads_path, params: {
          payload_concern: 'GenericWork',
          title: {
            first_file.id.to_s => 'Batch Visibility Work One',
            second_file.id.to_s => 'Batch Visibility Work Two'
          },
          uploaded_files: [first_file.id.to_s, second_file.id.to_s],
          batch_upload_item: {
            payload_concern: 'GenericWork',
            creator: ['Batch Creator'],
            rights_statement: ['http://rightsstatements.org/vocab/InC/1.0/'],
            admin_set_id: admin_set.id.to_s,
            # Non-default visibility, so passing proves the batch choice was applied.
            visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          },
          agreement: '1'
        }
      end

      expect(response).to redirect_to(hyrax.my_works_path(locale: 'en'))

      works = Hyrax.query_service.find_all_of_model(model: GenericWork).to_a
      expect(works.map { |work| Array(work.title).first })
        .to contain_exactly('Batch Visibility Work One', 'Batch Visibility Work Two')
      expect(works.map(&:visibility))
        .to all(eq(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC))
    end
  end
end

# ## Dashboard Works New by Batch Page
# [Back to TOC](#table-of-contents)

# - [ ] In a sidebar:
#   - [ ] I can see a list of requirements for creating the new batch work:
#     - [ ] Describe your work
#     - [ ] Add files
#     - [ ] Check deposit agreement
#   - [ ] I can set my created works’ visibility
#     - [ ] Public
#     - [ ] Institution
#     - [ ] Embargo
#     - [ ] Lease
#     - [ ] Private

# ### Files

# ![image25](https://github.com/samvera/hyku/assets/19597776/1e598af6-571e-4bcd-8274-b4cdc2836b3b)

# ### As a user:

# - [ ] I can see a button to Add files
# - [ ] I can see a button to Add folder
# - [ ] Once I’ve added a file, I can set the display label and resource type associated with that file
#   - [ ] I can see a button to set all files’ resource type to the selected resource type
# - [ ] I can see a button to delete an individual file as to not add it to the work

# ### Descriptions

# ![image43](https://github.com/samvera/hyku/assets/19597776/9f0a5aa2-57df-45e9-8b5a-fe5939793f42)

# ### As a user:

# - [ ] I can see three required fields to describe my works:
#   - [ ] Creator
#   - [ ] Keyword
#   - [ ] Rights Statement
# - [ ] I can see a button to display Additional fields to describe my works with

# ### Relationships

# ![image47](https://github.com/samvera/hyku/assets/19597776/e93b87c5-ebd1-4301-927a-149e40161395)

# ### As a user:

# - [ ] I can see a dropdown to select which Administrative Set to deposit my works into
# - [ ] I can see a dropdown to search for existing collections for which to add my work to
# - [ ] I can see a list of all selected collections to add my works to
#   - [ ] I can see a Remove from collection button

# ### Sharing

# ![image30](https://github.com/samvera/hyku/assets/19597776/2ba77b5b-3059-47b6-908b-24667ebe5a96)

# ### As a user:

# - [ ] I can see a form to add groups to have specific access to my created works
#   - [ ] Search for existing group to share with
#   - [ ] Choose Access level (View/Download, Edit)
#   - [ ] Add
# - [ ] I can see a form to add individual users to have specific access to my created works
#   - [ ] Search for existing user
#   - [ ] Choose Access level (View/Download, Edit)
#   - [ ] Add
# - [ ] I can see a list of all the groups / users I am currently sharing my works with, along with their respective access levels
# - [ ] If I add a new group / user, I can see a flash notification informing me that permissions aren’t save until the works are saved