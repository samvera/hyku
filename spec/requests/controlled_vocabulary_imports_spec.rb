# frozen_string_literal: true

RSpec.describe 'Controlled vocabulary imports', type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }

  # Users and roles are per-tenant, so an admin created outside the switch has no
  # privileges inside it and every request redirects.
  attr_reader :admin

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account:)
      @admin = create(:admin)
      vocabulary = Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms')
      vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille')
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  # Loaded inside the switch, not returned as a relation: a relation is lazy, so it
  # would run its query after the switch closed and read the wrong schema.
  def terms
    Apartment::Tenant.switch(account.tenant) do
      Qa::LocalAuthority.find_by(name: 'reading_rooms').local_authority_entries.to_a
    end
  end

  def upload(content, filename = 'terms.csv')
    file = Tempfile.new(['terms', File.extname(filename)])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'text/csv', original_filename: filename)
  end

  def hidden_value(name)
    response.body[/name="#{name}"[^>]*value="([^"]*)"/, 1]
  end

  def post_upload(content)
    post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/import",
         params: { file: upload(content) }
  end

  def post_confirm(overrides = {})
    post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/import/confirm",
         params: { payload: hidden_value('payload'), filename: hidden_value('filename'),
                   state_digest: hidden_value('state_digest') }.merge(overrides)
  end

  context 'as an admin' do
    before { login_as(admin, scope: :user) }

    it 'offers the upload form with a link to the csv template' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/import/new"

      expect(response).to have_http_status(:success)
      expect(response.body).to include 'controlled_vocabularies/reading_rooms.csv'
    end

    it 'reviews an upload without saving anything' do
      post_upload("id,label\nbraille,Braille Type\nmoon,Moon Type\n")

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Moon Type').and include('Braille Type')
      expect(terms.size).to eq 1
      expect(terms.first.label).to eq 'Braille'
    end

    it 'applies the reviewed file on confirm and returns to the vocabulary' do
      post_upload("id,label\nbraille,Braille Type\nmoon,Moon Type\n")
      post_confirm

      expect(response.location).to include '/dashboard/controlled_vocabularies/reading_rooms'
      expect(terms.map(&:label)).to contain_exactly('Braille Type', 'Moon Type')
    end

    it 'reports a no-change upload without a confirm button' do
      post_upload("id,label\nbraille,Braille\n")

      expect(response.body).to include I18n.t('hyku.admin.controlled_vocabulary.import.no_changes')
      expect(response.body).not_to include 'state_digest'
    end

    it 'lists row errors on review and withholds the confirm button' do
      post_upload("id,label\nbraille,Braille Type\nmoon,\n")

      expect(response.body).to include I18n.t('hyku.admin.controlled_vocabulary.import.errors_heading')
      expect(response.body).not_to include 'state_digest'
      expect(terms.first.label).to eq 'Braille'
    end

    it 'sends an unreadable file back to the upload form with nothing saved' do
      post_upload("label\n\"unclosed\n")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(terms.size).to eq 1
    end

    it 'requires a file' do
      post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/import"

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'treats a non-file value posted as the file like a missing file' do
      post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/import",
           params: { file: 'not a file' }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'declines a file over the size cap with a clear message' do
      stub_const('ControlledVocabularyImport::MAX_BYTES', 10)

      post_upload("id,label\nmoon,Moon Type\n")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include I18n.t('hyku.admin.controlled_vocabulary.import.file_too_large')
      expect(terms.size).to eq 1
    end

    it 'declines an oversized payload posted straight to confirm' do
      post_upload("id,label\nbraille,Braille Type\n")
      stub_const('ControlledVocabularyImport::MAX_BYTES', 10)

      post_confirm

      expect(response).to have_http_status(:unprocessable_entity)
      expect(terms.first.label).to eq 'Braille'
    end

    it 're-reviews instead of applying when the vocabulary changed since review' do
      post_upload("id,label\nbraille,Braille Type\n")
      Apartment::Tenant.switch(account.tenant) do
        Qa::LocalAuthority.find_by(name: 'reading_rooms')
                          .local_authority_entries.create!(label: 'Haptic', uri: 'haptic')
      end

      post_confirm

      expect(response.body).to include I18n.t('hyku.admin.controlled_vocabulary.import.stale')
      expect(terms.map(&:label)).to contain_exactly('Braille', 'Haptic')
    end

    it 'rejects a corrupted payload' do
      post_upload("id,label\nbraille,Braille Type\n")
      post_confirm(payload: 'not base64!')

      expect(response.location).to include '/import/new'
      expect(terms.first.label).to eq 'Braille'
    end

    it 'returns not found for a vocabulary that does not take imports' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/licenses/import/new"

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'as a user who can view but not manage' do
    before do
      user = Apartment::Tenant.switch(account.tenant) { create(:user) }
      allow_any_instance_of(Ability).to receive(:can_import_works?).and_return(true)
      login_as(user, scope: :user)
    end

    it 'refuses the form' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/import/new"

      expect(response).not_to have_http_status(:success)
    end

    it 'refuses the upload' do
      post_upload("id,label\nmoon,Moon Type\n")

      expect(terms.size).to eq 1
    end
  end
end
