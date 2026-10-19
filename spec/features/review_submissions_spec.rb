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
      creator: ['Pending Review Depositor'],
      title: ['Pending review work'],
      visibility_setting: 'open'
    )
  end

  before { login_as reviewer }

  # Each row of the workflows table as [Work, Depositor, Submission Date, Status] cell text.
  def table_rows
    Capybara.string(response.body).all('table.works-list tbody tr').map { |tr| tr.all('td').map { |td| td.text.strip } }
  end

  def table_headers
    Capybara.string(response.body).all('table.works-list thead th').map(&:text)
  end

  # NOTE: Hyrax's admin/workflows/index.html.erb labels this column "Depositor" but
  # renders the work's `creator` metadata (`document.creator`), not the depositing
  # user's account, so we assert on the creator value.
  # Update this test to assert on the depositor when issue #xxxx is fixed. Fix goes in
  # Hyrax (samvera/hyrax): app/views/hyrax/admin/workflows/index.html.erb.
  it 'lists a pending submission with its work, depositor, submission date and status' do
    get '/admin/workflows'

    expect(response).to have_http_status(:success)
    # Hyrax's locale renders the Status header lowercase (heading.status: "status").
    expect(table_headers).to eq(['Work', 'Depositor', 'Submission Date', 'status'])
    expect(table_rows.size).to eq(1)
    title, depositor, date, status = table_rows.first
    expect([title, depositor, status]).to eq(['Pending review work', 'Pending Review Depositor', 'pending_review'])
    expect(date).to match(/\A\d{4}-\d{2}-\d{2}/)
  end

  it 'approves a pending submission and changes its workflow state' do
    expect(Sipity::Entity(work).workflow_state.name).to eq('pending_review')

    put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'approve', comment: '' } }

    expect(response).to have_http_status(:redirect)
    expect(Sipity::Entity(work).reload.workflow_state.name).to eq('deposited')
  end

  # one_step_mediated_deposit has no "reject" action; a reviewer sends a work back with
  # request_changes, which moves it from pending_review to changes_required.
  it 'requests changes on a pending submission and changes its workflow state' do
    put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'request_changes', comment: 'Needs revision' } }

    expect(response).to have_http_status(:redirect)
    expect(Sipity::Entity(work).reload.workflow_state.name).to eq('changes_required')
  end

  it 'lists only deposited works, with their depositor, date and status, under the Published tab' do
    put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'approve', comment: '' } }
    expect(Sipity::Entity(work).reload.workflow_state.name).to eq('deposited')
    FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, admin_set:, depositor: creator.user_key,
                                                                        creator: ['Still Waiting Depositor'],
                                                                        title: ['Still waiting work'],
                                                                        visibility_setting: 'open')

    get '/admin/workflows', params: { state: 'published' }

    expect(response).to have_http_status(:success)
    # Count copy from hyrax.admin.workflows.index.works_published.
    expect(response.body).to match(%r{<strong>1 works</strong> published}i)
    expect(table_headers).to eq(['Work', 'Depositor', 'Submission Date', 'status'])
    expect(table_rows.size).to eq(1)
    title, depositor, date, status = table_rows.first
    expect([title, depositor, status]).to eq(['Pending review work', 'Pending Review Depositor', 'deposited'])
    expect(date).to match(/\A\d{4}-\d{2}-\d{2}/)

    # The Under Review tab now holds only the still-pending work.
    get '/admin/workflows'
    expect(table_rows.map { |row| [row[0], row[3]] }).to eq([['Still waiting work', 'pending_review']])
  end
end
