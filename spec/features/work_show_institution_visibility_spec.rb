# frozen_string_literal: true

RSpec.describe "Users trying to access an Institution Work's show page", type: :feature, clean: true, js: true do # rubocop:disable Metrics/LineLength
  let(:fake_solr_document) do
    {
      'has_model_ssim': ['GenericWork'],
      id: SecureRandom.uuid,
      'title_tesim': ['Institution GenericWork'],
      'admin_set_tesim': ['Default Admin Set'],
      'suppressed_bsi': false,
      'read_access_group_ssim': ['registered'],
      'edit_access_group_ssim': ['admin'],
      'edit_access_person_ssim': ['fake@example.com'],
      'visibility_ssi': 'authenticated'
    }
  end

  before do
    solr = Blacklight.default_index.connection
    solr.add(fake_solr_document)
    solr.commit
  end

  context 'an unauthenticated user' do
    it 'is redirected to the login view' do
      visit "/concern/generic_works/#{fake_solr_document[:id]}"
      expect(page).to have_content('You are not authorized to access this page.')
      expect(page).to have_content('Log in')
    end
  end

  context 'a registered user' do
    let(:tenant_user) { create(:user) }

    it 'is authorized' do
      login_as tenant_user
      visit "/concern/generic_works/#{fake_solr_document[:id]}"
      expect(page).to have_content('Institution GenericWork')
      expect(page).not_to have_content('Unauthorized')
    end
  end

  context 'an admin user' do
    let(:tenant_admin) { create(:admin) }

    it 'is authorized' do
      login_as tenant_admin
      visit "/concern/generic_works/#{fake_solr_document[:id]}"
      expect(page).to have_content('Institution GenericWork')
      expect(page).not_to have_content('Unauthorized')
    end
  end
end
