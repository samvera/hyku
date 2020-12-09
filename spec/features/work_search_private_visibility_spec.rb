# frozen_string_literal: true

RSpec.describe 'Users trying to search for a Private Work', type: :feature, clean: true, js: true do
  let(:fake_solr_document) do
    {
      'has_model_ssim': ['GenericWork'],
      id: SecureRandom.uuid,
      'title_tesim': ['Private GenericWork'],
      'admin_set_tesim': ['Default Admin Set'],
      'suppressed_bsi': false,
      'edit_access_group_ssim': ['admin'],
      'edit_access_person_ssim': ['fake@example.com'],
      'visibility_ssi': 'restricted'
    }
  end

  before do
    solr = Blacklight.default_index.connection
    solr.add(fake_solr_document)
    solr.commit
  end

  context 'an unauthenticated user' do
    it 'cannot see the work in the search results' do
      visit '/catalog'
      expect(page).to have_content('No results found for your search')
      expect(page).not_to have_content('Private GenericWork')
    end
  end

  context 'a registered user' do
    let(:tenant_user) { create(:user) }

    it 'cannot see the work in the search results' do
      login_as tenant_user
      visit '/catalog'
      expect(page).to have_content('No results found for your search')
      expect(page).not_to have_content('Private GenericWork')
    end
  end

  context 'an admin user' do
    let(:tenant_admin) { create(:admin) }

    it 'can see the work in the search results' do
      login_as tenant_admin
      visit '/catalog'
      expect(page).to have_content('Private GenericWork')
    end
  end
end
