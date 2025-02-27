# frozen_string_literal: true

RSpec.describe "Users trying to access a Public Work's show page", type: :feature, clean: true, js: true do # rubocop:disable Layout/LineLength
  let(:id) { SecureRandom.uuid }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:work) { double(GenericWork, id: id, visibility: visibility) }
  let(:fake_solr_document) do
    {
      'has_model_ssim': ['GenericWork'],
      id: id,
      'title_tesim': ['Public GenericWork'],
      'admin_set_tesim': ['Default Admin Set'],
      'suppressed_bsi': false,
      'read_access_group_ssim': ['public'],
      'edit_access_group_ssim': ['admin'],
      'edit_access_person_ssim': ['fake@example.com'],
      'visibility_ssi': visibility
    }
  end

  before do
    solr = Blacklight.default_index.connection
    solr.add(fake_solr_document)
    solr.commit
    allow(Hyrax.query_service).to receive(:find_by).with(id: id).and_return(work)
  end

  context 'an unauthenticated user' do
    it 'is authorized' do
      visit "/concern/generic_works/#{fake_solr_document[:id]}"
      expect(page).to have_content('Public GenericWork')
      expect(page).not_to have_content('Unauthorized')
      expect(page).not_to have_content('Log in')
    end
  end

  context 'a registered user' do
    let(:tenant_user) { create(:user) }

    it 'is authorized' do
      login_as tenant_user
      visit "/concern/generic_works/#{fake_solr_document[:id]}"
      expect(page).to have_content('Public GenericWork')
      expect(page).not_to have_content('Unauthorized')
      expect(page).not_to have_content('Log in')
    end
  end

  context 'an admin user' do
    let(:tenant_admin) { create(:admin) }

    it 'is authorized' do
      login_as tenant_admin
      visit "/concern/generic_works/#{fake_solr_document[:id]}"
      expect(page).to have_content('Public GenericWork')
      expect(page).not_to have_content('Unauthorized')
      expect(page).not_to have_content('Log in')
    end
  end
end
