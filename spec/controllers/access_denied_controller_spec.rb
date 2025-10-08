# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessDeniedController, type: :controller do
  describe '#show' do
    context 'with metadata_profiles reason' do
      before do
        get :show, params: { reason: 'metadata_profiles' }
      end

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'renders the show template' do
        expect(response).to render_template(:show)
      end

      it 'sets the correct title from locale' do
        expect(assigns(:title)).to eq(I18n.t('hyku.access_denied.metadata_profiles.title'))
      end

      it 'sets the correct message from locale' do
        expect(assigns(:message)).to eq(I18n.t('hyku.access_denied.metadata_profiles.message'))
      end

      it 'sets the correct details from locale' do
        expect(assigns(:details)).to eq(I18n.t('hyku.access_denied.metadata_profiles.details'))
      end

      it 'sets the reason parameter' do
        expect(assigns(:reason)).to eq('metadata_profiles')
      end
    end

    context 'with unknown reason' do
      before do
        get :show, params: { reason: 'unknown_reason' }
      end

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'renders the show template' do
        expect(response).to render_template(:show)
      end

      it 'sets default title' do
        expect(assigns(:title)).to eq(I18n.t('hyku.access_denied.default.title', default: 'Access Denied'))
      end

      it 'sets default message' do
        expect(assigns(:message)).to eq(I18n.t('hyku.access_denied.default.message', default: 'You do not have permission to access this resource.'))
      end

      it 'sets default details' do
        expect(assigns(:details)).to eq(I18n.t('hyku.access_denied.default.details', default: 'Please contact your administrator if you believe this is an error.'))
      end
    end

    context 'without reason parameter' do
      before do
        get :show
      end

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'renders the show template' do
        expect(response).to render_template(:show)
      end

      it 'uses default messages when no reason provided' do
        expect(assigns(:title)).to eq(I18n.t('hyku.access_denied.default.title', default: 'Access Denied'))
        expect(assigns(:message)).to eq(I18n.t('hyku.access_denied.default.message', default: 'You do not have permission to access this resource.'))
        expect(assigns(:details)).to eq(I18n.t('hyku.access_denied.default.details', default: 'Please contact your administrator if you believe this is an error.'))
      end
    end

    context 'with different locales' do
      it 'uses German translations when locale is German' do
        I18n.with_locale(:de) do
          get :show, params: { reason: 'metadata_profiles' }
          expect(assigns(:title)).to eq('Zugriff auf Metadatenprofile verweigert')
        end
      end

      it 'uses Spanish translations when locale is Spanish' do
        I18n.with_locale(:es) do
          get :show, params: { reason: 'metadata_profiles' }
          expect(assigns(:title)).to eq('Acceso a Perfiles de Metadatos Denegado')
        end
      end

      it 'uses French translations when locale is French' do
        I18n.with_locale(:fr) do
          get :show, params: { reason: 'metadata_profiles' }
          expect(assigns(:title)).to eq('Accès aux Profils de Métadonnées Refusé')
        end
      end
    end
  end
end