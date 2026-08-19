# frozen_string_literal: true

RSpec.describe 'Controlled vocabularies', type: :request, clean: true, multitenant: true do
  let(:account) { create(:account) }

  # Users and roles are per-tenant, so an admin created outside the switch has no
  # privileges inside it and every request redirects.
  attr_reader :admin

  # Derived rather than written out: param_key drops the Qa module, so the form
  # nests fields under local_authority and a hand-written key would not match.
  let(:param_key) { Qa::LocalAuthority.model_name.param_key }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account:)
      @admin = create(:admin)
      vocabulary = Qa::LocalAuthority.create!(name: 'reading_rooms',
                                              label: 'Reading Rooms',
                                              description: 'Where an item may be consulted on site.')
      vocabulary.local_authority_entries.create!(label: 'Special Collections', uri: 'special-collections')
      vocabulary.local_authority_entries.create!(label: 'Closed Stacks', uri: 'closed-stacks', active: false)
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  context 'as an admin' do
    before { login_as(admin, scope: :user) }

    describe 'the index' do
      it 'lists each vocabulary with the key to paste into a metadata profile' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies"

        expect(response).to have_http_status(:success)
        expect(response.body).to include 'Reading Rooms'
        expect(response.body).to include 'reading_rooms'
      end

      # Only vocabularies managed here have one, so it sits under the name rather
      # than in a column that would be empty for most rows.
      it 'shows the description of a vocabulary that has one' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies"

        expect(response.body).to include 'Where an item may be consulted on site.'
      end
    end

    describe 'a vocabulary' do
      # Looked up by name rather than database id, so the url matches the key a
      # metadata profile cites.
      it 'lists the terms, marking the retired one' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

        expect(response).to have_http_status(:success)
        expect(response.body).to include 'Special Collections'
        expect(response.body).to include 'Closed Stacks'
        expect(response.body).to include 'Inactive'
      end

      it 'shows the term id works store' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

        expect(response.body).to include 'special-collections'
      end
    end

    # A yaml-backed vocabulary has terms worth reading even though staff cannot
    # change them here. The suite seeds every real yaml name into the tables, so
    # this stands in a vocabulary that only a file backs.
    describe 'a vocabulary defined in a configuration file' do
      before do
        allow(ControlledVocabularyCatalog).to receive(:file_based_names).and_return(%w[map_regions])
        allow(Qa::Authorities::Local).to receive(:subauthority_for).and_call_original
        allow(Qa::Authorities::Local).to receive(:subauthority_for)
          .with('map_regions')
          .and_return(instance_double(Qa::Authorities::Local::FileBasedAuthority,
                                      all: [{ 'id' => 'north', 'label' => 'North', 'active' => true }]))
      end

      it 'lists its terms and says they cannot be changed here' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/map_regions"

        expect(response).to have_http_status(:success)
        expect(response.body).to include 'North'
        expect(response.body).to include 'configuration file'
      end
    end

    it 'returns not found for a vocabulary that does not exist' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/not_a_vocabulary"

      expect(response).to have_http_status(:not_found)
    end

    describe 'creating a vocabulary' do
      it 'offers the form' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/new"

        expect(response).to have_http_status(:success)
      end

      it 'creates the vocabulary and opens it so terms can be added' do
        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: 'Lab Names', description: 'Where the work was done.' } }

        vocabulary = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.find_by(name: 'lab_names') }

        expect(vocabulary.label).to eq 'Lab Names'
        expect(vocabulary.description).to eq 'Where the work was done.'
        # The app appends a locale param, so match the path rather than the whole url.
        expect(response.location).to include '/dashboard/controlled_vocabularies/lab_names'
      end

      it 'ignores a name supplied in the request' do
        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: 'Lab Names', name: 'something_else' } }

        names = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.pluck(:name) }

        expect(names).to include 'lab_names'
        expect(names).not_to include 'something_else'
      end

      it 'redisplays the form when the vocabulary is not valid' do
        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include 'Name'
      end

      # An accented label is the case a client-side preview would get wrong:
      # parameterize transliterates, so the key is cafe_terms, not caf_terms.
      it 'shows the source key it will use when redisplaying' do
        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: 'Café Terms' } }
        # Duplicate the label so the form comes back rather than saving.
        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: 'Café Terms' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include 'cafe_terms'
      end
    end
  end

  context 'as a user with no deposit access' do
    before do
      user = Apartment::Tenant.switch(account.tenant) { create(:user) }
      login_as(user, scope: :user)
    end

    it 'refuses the page' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies"

      expect(response).not_to have_http_status(:success)
    end
  end

  # Viewing is granted to depositors, creating only to admins, so the two abilities
  # have to gate different actions.
  context 'as a user who can view but not manage' do
    before do
      user = Apartment::Tenant.switch(account.tenant) { create(:user) }
      allow_any_instance_of(Ability).to receive(:can_import_works?).and_return(true)
      login_as(user, scope: :user)
    end

    it 'allows the listing' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies"

      expect(response).to have_http_status(:success)
    end

    it 'refuses the form' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/new"

      expect(response).not_to have_http_status(:success)
    end

    it 'refuses the create' do
      post "http://#{account.cname}/dashboard/controlled_vocabularies",
           params: { param_key => { label: 'Lab Names' } }

      created = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.exists?(name: 'lab_names') }

      expect(created).to be false
    end
  end

  # Vocabularies live in per-tenant Apartment schemas, so one tenant's terms must
  # never appear in another's dashboard.
  context 'in another tenant' do
    let(:other_account) { create(:account) }

    before do
      Apartment::Tenant.create(other_account.tenant)
      other_admin = Apartment::Tenant.switch(other_account.tenant) do
        Site.update(account: other_account)
        create(:admin)
      end
      login_as(other_admin, scope: :user)
    end

    after { Apartment::Tenant.drop(other_account.tenant) }

    it 'does not show the first tenant\'s vocabulary' do
      get "http://#{other_account.cname}/dashboard/controlled_vocabularies"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include 'Reading Rooms'
    end
  end
end
