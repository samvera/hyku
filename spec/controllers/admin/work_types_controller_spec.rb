# frozen_string_literal: true

RSpec.describe Admin::WorkTypesController, singletenant: true do
  context 'as an anonymous user' do
    describe 'GET #index' do
      subject { get :edit }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  context 'as an admin user' do
    before { sign_in create(:admin) }

    describe 'GET #edit' do
      subject { get :edit }

      it { is_expected.to render_template('layouts/hyrax/dashboard') }
      it { is_expected.to render_template('admin/work_types/edit') }
    end

    describe 'PATCH #update' do
      before { patch :update, params: { available_works: ['Image'] } }

      it 'updates attribtes' do
        expect(Site.instance.available_works).to include('Image')
        expect(Site.instance.available_works).not_to include('GenericWork')
        expect(Site.instance.available_works.size).to eq 1
      end
    end
  end
end
