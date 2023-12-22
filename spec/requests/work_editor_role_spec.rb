# frozen_string_literal: true

# For work approval permissions, see spec/requests/work_approval_permissions_spec.rb
RSpec.describe 'Work Editor role', type: :request, singletenant: true, clean: true do
  include WorksHelper

  # `before`s and `let!`s are order-dependent -- do not move this `before` from the top
  before do
    FactoryBot.create(:admin_group)
    FactoryBot.create(:registered_group)
    FactoryBot.create(:editors_group)
    FactoryBot.create(:depositors_group)
  end
  let(:work_editor) { FactoryBot.create(:user, roles: [:work_editor]) }
  let(:work_depositor) { FactoryBot.create(:user, roles: [:work_depositor]) }
  let(:visibility) { 'open' }
  let(:valid_work_params) do
    {
      generic_work: {
        title: ['Test Work'],
        creator: ['depositor@example.com'],
        keyword: ['asdf'],
        rights_statement: 'http://rightsstatements.org/vocab/CNE/1.0/',
        visibility:,
        admin_set_id: admin_set.id
      }
    }
  end
  let!(:admin_set) do
    admin_set = AdminSet.new(title: ['Test Admin Set'])
    allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('default')
    Hyrax::AdminSetCreateService.new(admin_set:, creating_user: nil).create
    admin_set.reload
  end
  let!(:work) { process_through_actor_stack(build(:work), work_depositor, admin_set.id, visibility) }

  describe 'read permissions' do
    %w[open authenticated restricted].each do |visibility|
      context "with #{visibility} visibility" do
        let(:visibility) { visibility }

        before do
          login_as work_editor
        end
        it 'can see the show page for works it deposited' do
          my_work = process_through_actor_stack(build(:work), work_editor, admin_set.id, visibility)
          get hyrax_generic_work_path(my_work)

          expect(response).to have_http_status(:success)
        end

        it 'can see the show page for works deposited by other users' do
          get hyrax_generic_work_path(work)

          expect(response).to have_http_status(:success)
        end

        it 'can see works it deposited in the dashboard' do
          process_through_actor_stack(build(:work), work_editor, admin_set.id, visibility)
          get '/dashboard/my/works'

          expect(response).to have_http_status(:success)
        end

        it 'can see works deposited by other users in the dashboard' do
          get '/dashboard/works'

          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe 'create permissions' do
    it 'can see the work form' do
      login_as work_editor
      get new_hyrax_generic_work_path

      expect(response).to have_http_status(:success)
    end

    it 'can create a work' do
      login_as work_editor
      expect { post hyrax_generic_works_path, params: valid_work_params }
        .to change(GenericWork, :count).by(1)
    end
  end

  describe 'edit permissions' do
    it 'can edit works deposited by other users' do
      login_as work_editor
      get edit_hyrax_generic_work_path(work)

      expect(response).to have_http_status(:success)
    end

    it 'can edit works it deposited' do
      login_as work_editor
      my_work = process_through_actor_stack(build(:work), work_editor, admin_set.id, visibility)
      get edit_hyrax_generic_work_path(my_work)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'destroy permissions' do
    it 'cannot destroy the work' do
      login_as work_editor
      expect { delete hyrax_generic_work_path(work) }
        .not_to change(GenericWork, :count)
    end
  end
end
