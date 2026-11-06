# frozen_string_literal: true

RSpec.describe 'Batch uploads', type: :request, singletenant: true, clean: true do
  let(:user) { create(:user, roles: [:work_depositor]) }
  let(:admin_set) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }
  let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set.id.to_s) }

  before do
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    allow(Flipflop).to receive(:batch_upload?).and_return(true)

    # The actor stack needs an active workflow and deposit access to persist works.
    workflow = Sipity::Workflow.find_or_create_by!(name: 'batch-test-workflow', permission_template:) do |wf|
      wf.active = true
    end
    Sipity::WorkflowAction.find_or_create_by!(name: 'submit', workflow:)
    Hyrax::PermissionTemplateAccess.find_or_create_by!(
      permission_template_id: permission_template.id,
      agent_type: 'user',
      agent_id: user.user_key,
      access: 'deposit'
    )
    login_as user
  end

  def batch_uploaded_file
    Hyrax::UploadedFile.create(user:, file: File.open(File.join(file_fixture_path, 'hyrax', 'image.jp2')))
  end

  # Manual test plan: "I can set my created works' visibility".
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
          # Single-valued, as the batch form posts it (an array would be dropped by
          # the form's permitted params; flexible mode requires a rights statement).
          rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
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
