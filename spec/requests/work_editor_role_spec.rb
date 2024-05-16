# frozen_string_literal: true

# For work approval permissions, see spec/requests/work_approval_permissions_spec.rb
RSpec.describe 'Work Editor role', type: :request, singletenant: true, clean: true do
  include WorksHelper

  # `before`s and `let!`s are order-dependent -- do not move this `before` from the top
  before do
    allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('default')
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

  let(:depositor) { work_depositor.user_key }

  let!(:admin_set) do
    FactoryBot.valkyrie_create(:hyku_admin_set, title: ['Test Admin Set'], with_permission_template: { with_workflows: true })
  end
  let(:work) do
    FactoryBot.valkyrie_create(:generic_work_resource,
                               :with_admin_set,
                               visibility_setting: visibility,
                               depositor: work_depositor.user_key,
                               admin_set:)
  end

  describe 'read permissions' do
    %w[open authenticated restricted].each do |visibility|
      context "with #{visibility} visibility" do
        let(:visibility) { visibility }
        let(:my_work) do
          FactoryBot.valkyrie_create(:generic_work_resource,
                                                    :with_admin_set,
                                                    visibility_setting: visibility,
                                                    depositor: work_editor.user_key,
                                                    admin_set:)
        end

        before do
          login_as work_editor
        end

        it 'can see the show page for works it deposited' do
          # We're testing existing AF objects and Valkyrie objects.  They both should pass.
          af_admin_set = FactoryBot.create(:admin_set, with_permission_template: { with_workflows: true })
          af_work = process_through_actor_stack(build(:work), work_editor, af_admin_set.id, visibility)

          get hyrax_generic_work_path(af_work)
          expect(response).to have_http_status(:success)

          get hyrax_generic_work_path(my_work)
          expect(response).to have_http_status(:success)
        end

        it 'can see the show page for works deposited by other users' do
          get hyrax_generic_work_path(work)

          expect(response).to have_http_status(:success)
        end

        it 'can see works it deposited in the dashboard' do
          my_work
          get '/dashboard/my/works'

          expect(response).to have_http_status(:success)
        end

        it 'can see works deposited by other users in the dashboard' do
          work
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

    # This is commented out as I was encountering issues reported here:
    # https://github.com/samvera/hyrax/issues/6775
    xit 'can create a work' do
      login_as work_editor
      expect(Ability.new(work_editor).can?(:create, GenericWorkResource)).to be_truthy
      expect do
        post hyrax_generic_works_path, params: valid_work_params
      end.to change { Hyrax.query_service.count_all_of_model(model: GenericWorkResource) }.by(1)
    end
  end

  describe 'edit permissions' do
    it 'can edit works deposited by other users' do
      login_as work_editor
      get edit_hyrax_generic_work_path(work)

      expect(response).to have_http_status(:success)
    end

    it 'can edit works it deposited' do
      my_work = FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, admin_set:, visibility_setting: visibility, depositor: work_editor.user_key)

      expect(Ability.new(work_editor).can?(:edit, my_work)).to be_truthy

      login_as work_editor

      get edit_hyrax_generic_work_path(my_work)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'destroy permissions' do
    it 'cannot destroy the work' do
      work # We need to instantiate this before we try to destroy it
      expect(Ability.new(work_editor).can?(:destroy, work)).to be_falsey
      login_as work_editor
      expect { delete hyrax_generic_work_path(work) }
        .not_to change { Hyrax.query_service.count_all_of_model(model: GenericWorkResource) }
    end
  end
end
