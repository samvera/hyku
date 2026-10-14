# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Review submissions', type: :request, singletenant: true, clean: true do
  let(:reviewer) { create(:admin) }
  let(:creator) { create(:user) }
  let!(:admin_group) { create(:admin_group, member_users: [reviewer]) }
  let!(:admin_set) do
    allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('one_step_mediated_deposit')
    Hyrax::AdminSetCreateService.call!(
      admin_set: AdminSet.new(title: ['Review Admin Set']),
      creating_user: nil
    )
  end
  let!(:work) do
    FactoryBot.valkyrie_create(
      :generic_work_resource,
      :with_admin_set,
      admin_set:,
      depositor: creator.user_key,
      title: ['Pending review work'],
      visibility_setting: 'open'
    )
  end

  before { login_as reviewer }

  it 'lists a pending submission with its depositor and status' do
    get '/admin/workflows'

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Pending review work')
    expect(response.body).to include(creator.email)
    expect(response.body).to match(/Under Review|pending/i)
  end

  it 'approves a pending submission and changes its workflow state' do
    expect(Sipity::Entity(work).workflow_state.name).to eq('pending_review')

    put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'approve', comment: '' } }

    expect(response).to have_http_status(:redirect)
    expect(Sipity::Entity(work).reload.workflow_state.name).to eq('deposited')
  end

  it 'rejects a pending submission and changes its workflow state' do
    put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'reject', comment: 'Needs revision' } }

    expect(response).to have_http_status(:redirect)
    expect(Sipity::Entity(work).reload.workflow_state.name).not_to eq('pending_review')
  end

  it 'shows a submission date column in the under review list' do
    get '/admin/workflows'

    expect(response).to have_http_status(:success)
    # Column headers come from hyrax.admin.workflows.index.heading.*
    expect(response.body).to include('Work')
    expect(response.body).to include('Depositor')
    expect(response.body).to include('Submission Date')
    expect(response.body).to include('Pending review work')
  end

  it 'lists a published work under the Published tab once it has been deposited' do
    # Approve the pending work so it transitions into the 'deposited' state, which
    # the workflows controller surfaces on the Published tab (state=published).
    put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'approve', comment: '' } }
    expect(Sipity::Entity(work).reload.workflow_state.name).to eq('deposited')

    get '/admin/workflows', params: { state: 'published' }

    expect(response).to have_http_status(:success)
    # Published tab label and count copy (hyrax.admin.workflows.index.tabs.published /
    # .works_published) confirm we are viewing the deposited/published listing.
    expect(response.body).to include('Published')
    expect(response.body).to match(/works<\/strong> published|published/i)
    # Same columns as Under Review, including the submission date.
    expect(response.body).to include('Submission Date')
    expect(response.body).to include('Pending review work')
  end
end


# ## Review Submissions Page
# [Back to TOC](#table-of-contents)

# ### Under Review

# ![image22](https://github.com/samvera/hyku/assets/19597776/8216b4bd-00dd-4840-9ac6-5a3367398c4c)

# ### As an admin/approving user:

# - [ ] I can see a list of deposited works that require review before being published
# - [ ] For each work pending review, I can see the:
#   - [ ] Work
#   - [ ] Depositor
#   - [ ] Submission Date
#   - [ ] Status

# ### Published

# ![image7](https://github.com/samvera/hyku/assets/19597776/789c1883-2073-4296-81ea-9fb18ce994d3)

# ### As an admin/approving user:

# - [ ] I can see a list of deposited works that are published
# - [ ] For each published work, I can see the:
#   - [ ] Work
#   - [ ] Depositor
#   - [ ] Submission Date
#   - [ ] Status