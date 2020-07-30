# frozen_string_literal: true

RSpec.describe "OAI PMH Support", type: :feature do
  let(:user) { create(:user) }
  let(:work) { create(:work, user: user) }
  let(:identifier) { work.id }

  before do
    login_as(user, scope: :user)
    work
  end

  context 'oai interface with works present' do
    it 'lists metadata prefixess' do
      visit oai_catalog_path(verb: 'ListMetadataFormats')
      expect(page).to have_content('oai_dc')
    end

    it 'retrieves a list of records' do
      visit oai_catalog_path(verb: 'ListRecords', metadataPrefix: 'oai_dc')
      expect(page).to have_content("oai:hyku:#{identifier}")
      expect(page).to have_content(work.title.first)
    end

    it 'retrieves a single record' do
      visit oai_catalog_path(verb: 'GetRecord', metadataPrefix: 'oai_dc', identifier: identifier)
      expect(page).to have_content("oai:hyku:#{identifier}")
      expect(page).to have_content(work.title.first)
    end

    it 'retrieves a list of identifiers' do
      visit oai_catalog_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc')
      expect(page).to have_content("oai:hyku:#{identifier}")
      expect(page).not_to have_content(work.title.first)
    end
  end
end
