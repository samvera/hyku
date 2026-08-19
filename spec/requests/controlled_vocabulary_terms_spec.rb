# frozen_string_literal: true

RSpec.describe 'Controlled vocabulary terms', type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }

  # Users and roles are per-tenant, so an admin created outside the switch has no
  # privileges inside it and every request redirects.
  attr_reader :admin

  # Derived rather than written out: param_key drops the Qa module, so the form nests
  # fields under local_authority_entry and a hand-written key would not match.
  let(:param_key) { Qa::LocalAuthorityEntry.model_name.param_key }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account:)
      @admin = create(:admin)
      Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms')
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  # Loaded inside the switch, not returned as a relation: a relation is lazy, so it
  # would run its query after the switch closed and read the wrong schema.
  def terms_in(vocabulary_name)
    Apartment::Tenant.switch(account.tenant) do
      Qa::LocalAuthority.find_by(name: vocabulary_name).local_authority_entries.to_a
    end
  end

  context 'as an admin' do
    before { login_as(admin, scope: :user) }

    it 'offers the form' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/new"

      expect(response).to have_http_status(:success)
    end

    it 'adds the term and returns to the vocabulary' do
      post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms",
           params: { param_key => { label: 'Special Collections', uri: 'special-collections' } }

      term = terms_in('reading_rooms').find { |t| t.uri == 'special-collections' }

      expect(term.label).to eq 'Special Collections'
      expect(term.active).to be true
      expect(response.location).to include '/dashboard/controlled_vocabularies/reading_rooms'
    end

    it 'uses the label as the term id when none is given' do
      post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms",
           params: { param_key => { label: 'Rare Books', uri: '' } }

      expect(terms_in('reading_rooms').map(&:uri)).to include 'Rare Books'
    end

    it 'redisplays the form when the term is not valid' do
      post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms",
           params: { param_key => { label: '' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(terms_in('reading_rooms').size).to eq 0
    end

    it 'refuses a duplicate term id within the vocabulary' do
      Apartment::Tenant.switch(account.tenant) do
        Qa::LocalAuthority.find_by(name: 'reading_rooms')
                          .local_authority_entries.create!(label: 'Rare Books', uri: 'rare-books')
      end

      post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms",
           params: { param_key => { label: 'Rare Book Room', uri: 'rare-books' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(terms_in('reading_rooms').size).to eq 1
    end

    it 'returns not found for a vocabulary this tenant does not own' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/licenses/terms/new"

      expect(response).to have_http_status(:not_found)
    end
  end

  # Viewing the listing is granted to depositors; adding terms is not.
  context 'as a user who can view but not manage' do
    before do
      user = Apartment::Tenant.switch(account.tenant) { create(:user) }
      allow_any_instance_of(Ability).to receive(:can_import_works?).and_return(true)
      login_as(user, scope: :user)
    end

    it 'refuses the form' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/new"

      expect(response).not_to have_http_status(:success)
    end

    it 'refuses the create' do
      post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms",
           params: { param_key => { label: 'Special Collections' } }

      expect(terms_in('reading_rooms').size).to eq 0
    end
  end
end
