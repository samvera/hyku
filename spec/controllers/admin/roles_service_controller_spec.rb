# frozen_string_literal: true

RSpec.describe Admin::RolesServiceController, type: :controller do
  context 'as an anonymous user' do
    describe 'GET #index' do
      subject { get :index }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  context 'as an admin user' do
    before { sign_in create(:admin) }

    describe 'GET #index' do
      subject { get :index }

      it { is_expected.to render_template('layouts/hyrax/dashboard') }
      it { is_expected.to render_template('admin/roles_service/index') }
    end
  end

  context 'as an admin user' do
    before { sign_in create(:admin) }

    describe 'GET #index' do
      subject { get :index }

      it { is_expected.to render_template('layouts/hyrax/dashboard') }
      it { is_expected.to render_template('admin/roles_service/index') }
    end

    describe 'POST #update_roles' do
      it 'submits a job when it receives a valid job name' do
        expect(RolesService::CreateCollectionAccessesJob).to receive(:perform_later)
        post :update_roles, params: { job_name_key: :create_collection_accesses }
      end
    end
  end
end
