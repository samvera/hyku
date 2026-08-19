# frozen_string_literal: true

RSpec.describe 'Controlled vocabularies', type: :request, clean: true, multitenant: true do
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

      context 'with a metadata profile' do
        before do
          allow(Hyrax.config).to receive(:flexible?).and_return(true)
          allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(
            'classes' => { 'GenericWorkResource' => { 'display_label' => 'Generic Work' } },
            'properties' => {
              'reading_room' => {
                'available_on' => { 'class' => ['GenericWorkResource'] },
                'controlled_values' => { 'sources' => ['reading_rooms'] },
                'display_label' => { 'default' => 'Reading Room' }
              }
            }
          )
        end

        it 'lists the properties citing the vocabulary with their work types' do
          get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

          expect(response.body).to include '<code>reading_room</code>'
          expect(response.body).to include 'Generic Work'
        end

        it 'says when no property cites the vocabulary' do
          get "http://#{account.cname}/dashboard/controlled_vocabularies/audience"

          expect(response.body).to include 'No metadata property uses this vocabulary'
        end
      end

      # Forms read mapped vocabularies from configuration files in this mode, so
      # the page must say term changes are out of staff hands.
      context 'without flexible metadata' do
        before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

        it 'still lists usage, and says the terms need a developer' do
          get "http://#{account.cname}/dashboard/controlled_vocabularies/licenses"

          expect(response.body).to include '<code>license</code>'
          expect(response.body).to include 'Changing its terms requires a developer.'
        end

        it 'does not warn on a vocabulary no form uses' do
          get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

          expect(response.body).not_to include 'Changing its terms requires a developer.'
        end

        # based_near autocompletes against GeoNames, so the vocabulary is in use,
        # but its terms live in the external service, not a configuration file.
        it 'shows usage for a remote authority without the configuration-file note' do
          get "http://#{account.cname}/dashboard/controlled_vocabularies/geonames"

          expect(response.body).to include '<code>based_near</code>'
          expect(response.body).not_to include 'Changing its terms requires a developer.'
        end

        # Seeded tenants hold licenses as tenant rows, and the qa fallback serves
        # the form from those rows, so no developer is needed to change them.
        it 'does not claim a database-backed vocabulary needs a developer' do
          Apartment::Tenant.switch(account.tenant) do
            Qa::LocalAuthority.create!(name: 'licenses', label: 'Licenses')
          end

          get "http://#{account.cname}/dashboard/controlled_vocabularies/licenses"

          expect(response.body).to include '<code>license</code>'
          expect(response.body).not_to include 'Changing its terms requires a developer.'
        end
      end

      # Flexible metadata on but the tenant has not saved a profile yet: usage is
      # unknowable, which is not the same as unused.
      context 'with flexible metadata but no profile' do
        before do
          allow(Hyrax.config).to receive(:flexible?).and_return(true)
          allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(nil)
        end

        it 'omits the usage row rather than calling the vocabulary unused' do
          get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

          expect(response).to have_http_status(:success)
          expect(response.body).not_to include 'Used by properties'
          expect(response.body).not_to include 'No metadata property uses this vocabulary'
        end
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

  context 'as a user who can deposit' do
    before do
      user = Apartment::Tenant.switch(account.tenant) { create(:user) }
      allow_any_instance_of(Ability).to receive(:can_import_works?).and_return(true)
      login_as(user, scope: :user)
    end

    it 'allows the page' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies"

      expect(response).to have_http_status(:success)
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
