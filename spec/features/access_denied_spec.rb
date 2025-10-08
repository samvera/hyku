# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Access Denied Page', type: :feature do
  describe 'visiting the access denied page' do
    context 'with metadata_profiles reason' do
      before do
        visit '/access_denied?reason=metadata_profiles'
      end

      it 'displays the correct title' do
        expect(page).to have_content('Metadata Profiles Access Denied')
      end

      it 'displays the correct message' do
        expect(page).to have_content('Access to metadata profiles is not available for search-only tenants.')
      end

      it 'displays the correct details' do
        expect(page).to have_content('This tenant is configured for search-only access. Administrative features like metadata profile management are restricted.')
      end

      it 'has a return to dashboard link' do
        expect(page).to have_link('Return to Dashboard', href: '/dashboard')
      end

      it 'has a go to home page link' do
        expect(page).to have_link('Go to Home Page', href: root_path)
      end

      it 'displays the warning alert style' do
        expect(page).to have_css('.alert.alert-warning')
      end

      it 'displays the exclamation triangle icon' do
        expect(page).to have_css('i.fa.fa-exclamation-triangle')
      end

      it 'has proper page title in head' do
        expect(page).to have_title(/Metadata Profiles Access Denied/)
      end
    end

    context 'with no reason parameter' do
      before do
        visit '/access_denied'
      end

      it 'displays default access denied message' do
        expect(page).to have_content('Access Denied')
        expect(page).to have_content('You do not have permission to access this resource.')
        expect(page).to have_content('Please contact your administrator if you believe this is an error.')
      end

      it 'still has navigation links' do
        expect(page).to have_link('Return to Dashboard')
        expect(page).to have_link('Go to Home Page')
      end
    end

    context 'with different locales' do
      it 'displays German content when locale is German' do
        I18n.with_locale(:de) do
          visit '/access_denied?reason=metadata_profiles'
          expect(page).to have_content('Zugriff auf Metadatenprofile verweigert')
          expect(page).to have_content('Der Zugriff auf Metadatenprofile ist für reine Suchinstanzen nicht verfügbar.')
        end
      end

      it 'displays Spanish content when locale is Spanish' do
        I18n.with_locale(:es) do
          visit '/access_denied?reason=metadata_profiles'
          expect(page).to have_content('Acceso a Perfiles de Metadatos Denegado')
          expect(page).to have_content('El acceso a los perfiles de metadatos no está disponible para inquilinos de solo búsqueda.')
        end
      end
    end

    context 'responsive design' do
      it 'has responsive column classes' do
        visit '/access_denied?reason=metadata_profiles'
        expect(page).to have_css('.col-lg-8.col-md-10.col-sm-12')
      end

      it 'has proper Bootstrap spacing classes' do
        visit '/access_denied?reason=metadata_profiles'
        expect(page).to have_css('.mt-5.mb-4')
        expect(page).to have_css('.text-center')
      end
    end
  end
end