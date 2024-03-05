# frozen_string_literal: true

RSpec.describe 'Work approval permissions', type: :request, singletenant: true, clean: true do
  include WorksHelper

  let(:user) { FactoryBot.create(:user) }
  let(:work_creator) { FactoryBot.create(:admin) }
  let(:valid_work_params) do
    {
      generic_work: {
        title: ['Test Work'],
        creator: [work_creator.email],
        keyword: ['asdf'],
        rights_statement: 'http://rightsstatements.org/vocab/CNE/1.0/',
        admin_set_id: admin_set.id
      }
    }
  end
  # These `let!` statements and the following `before` are order-dependent
  let!(:admin_group) { Hyrax::Group.find_or_create_by!(name: ::Ability.admin_group_name) }
  let!(:registered_group) { FactoryBot.create(:registered_group) } # rubocop:disable RSpec/LetSetup
  let!(:editors_group) { FactoryBot.create(:editors_group) }
  let!(:depositors_group) { FactoryBot.create(:depositors_group) }
  let!(:admin_set) do
    allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('one_step_mediated_deposit')
    admin_set = Hyrax.config.admin_set_class.new(title: ['Mediated Deposit Admin Set'])
    Hyrax::AdminSetCreateService.call!(admin_set:, creating_user: nil)
  end
  let(:visibility_setting) { 'open' }
  let!(:work) { FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, admin_set:, visibility_setting:, depositor: work_creator.user_key) }

  before do
    login_as user
  end

  context 'when signed in as an admin' do
    before do
      admin_group.add_members_by_id([user.id])
    end

    it 'can approve a work', ci: 'skip' do
      expect(Sipity::Entity(work).workflow_state.name).to eq('pending_review')

      put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'approve', comment: '' } }

      expect(Sipity::Entity(work).reload.workflow_state.name).to eq('deposited')
    end

    it 'can see works submitted for review in the dashboard' do
      get '/admin/workflows'

      expect(response).to have_http_status(:success)
    end
  end

  context 'when signed in as a work editor' do
    before do
      editors_group.add_members_by_id([user.id])
    end

    it 'can approve a work', ci: 'skip' do
      expect(Sipity::Entity(work).workflow_state.name).to eq('pending_review')

      put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'approve', comment: '' } }

      expect(Sipity::Entity(work).reload.workflow_state.name).to eq('deposited')
    end

    it 'can see works submitted for review in the dashboard' do
      get '/admin/workflows'

      expect(response).to have_http_status(:success)
    end
  end

  context 'when signed in as a work depositor' do
    before do
      depositors_group.add_members_by_id([user.id])
    end

    it 'cannot approve a work', ci: 'skip' do
      expect(Sipity::Entity(work).workflow_state.name).to eq('pending_review')

      put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'approve', comment: '' } }

      expect(response).to have_http_status(:unauthorized)
      expect(Sipity::Entity(work).reload.workflow_state.name).to eq('pending_review')
    end

    it 'cannot see works submitted for review in the dashboard' do
      get '/admin/workflows'

      expect(response).to have_http_status(:redirect)
    end
  end

  context 'when signed in as a user with no special access' do
    it 'cannot approve a work', ci: 'skip' do
      expect(Sipity::Entity(work).workflow_state.name).to eq('pending_review')

      put hyrax_workflow_action_path(work), params: { workflow_action: { name: 'approve', comment: '' } }

      expect(response).to have_http_status(:unauthorized)
      expect(Sipity::Entity(work).reload.workflow_state.name).to eq('pending_review')
    end

    it 'cannot see works submitted for review in the dashboard' do
      get '/admin/workflows'

      expect(response).to have_http_status(:redirect)
    end
  end
end
