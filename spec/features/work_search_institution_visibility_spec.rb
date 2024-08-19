# frozen_string_literal: true

RSpec.describe 'Users trying to search for an Institution Work', type: :feature, clean: true, js: true do # rubocop:disable Layout/LineLength
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
    it 'cannot see the work in the search results' do
      visit '/catalog'
      expect(page).to have_content('No results found for your search')
      expect(page).not_to have_content('Institution GenericWork')
    end
  end

  context 'a registered user' do
    let(:tenant_user) { create(:user) }

    it 'can see the work in the search results' do
      login_as tenant_user
      visit '/catalog'
      expect(page).to have_content('Institution GenericWork')
    end
  end

  context 'an admin user' do
    let(:tenant_admin) { create(:admin) }

    it 'can see the work in the search results' do
      login_as tenant_admin
      visit '/catalog'
      expect(page).to have_content('Institution GenericWork')
    end
  end
end
