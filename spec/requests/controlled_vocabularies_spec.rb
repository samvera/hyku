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

      # Hyrax sets `.table-responsive { overflow-x: visible }` app-wide, cancelling
      # Bootstrap's scroll for every table. Without the extra class the listing is
      # cut off at the container edge on a narrow screen rather than scrolling.
      it 'keeps the listing scrollable on a narrow screen' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies"

        expect(response.body).to include 'controlled-vocabularies-scroll'
      end

      # Only vocabularies managed here have one, so it sits under the name rather
      # than in a column that would be empty for most rows.
      it 'shows the description of a vocabulary that has one' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies"

        expect(response.body).to include 'Where an item may be consulted on site.'
      end

      it 'offers a download dropdown on downloadable rows only' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies"

        expect(response.body).to include 'controlled_vocabularies/reading_rooms.csv'
        expect(response.body).to include 'controlled_vocabularies/reading_rooms.yml'
        expect(response.body).not_to include 'controlled_vocabularies/geonames.csv'
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

      it 'says where the vocabulary comes from' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

        expect(response.body).to include 'This tenant'
      end

      it 'offers a download dropdown next to the add term button' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

        expect(response.body).to include 'controlled_vocabularies/reading_rooms.csv'
        expect(response.body).to include 'controlled_vocabularies/reading_rooms.yml'
      end

      it 'downloads the terms as csv, inactive terms included' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms.csv"

        expect(response.headers['Content-Disposition']).to include 'reading_rooms.csv'
        expect(response.body.lines.first).to eq "id,label,active\n"
        expect(response.body).to include "closed-stacks,Closed Stacks,false\n"
      end

      it 'downloads the terms as a qa authority yaml file' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms.yml"

        expect(response.headers['Content-Disposition']).to include 'reading_rooms.yml'
        expect(YAML.safe_load(response.body)['terms'])
          .to include('id' => 'special-collections', 'term' => 'Special Collections', 'active' => true)
      end

      it 'downloads without flexible metadata' do
        allow(Hyrax.config).to receive(:flexible?).and_return(false)

        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms.csv"

        expect(response).to have_http_status(:success)
      end

      it 'returns not found for a vocabulary whose terms cannot be exported' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/geonames.csv"

        expect(response).to have_http_status(:not_found)
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

      it 'downloads without a database row' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/map_regions.csv"

        expect(response.headers['Content-Disposition']).to include 'map_regions.csv'
        expect(response.body).to include "north,North,true\n"
      end
    end

    # Every authority has a page, because it reports where the vocabulary is used.
    # A remote service cannot be enumerated, so the page says where its terms live
    # rather than showing an empty list that reads as "none".
    describe 'a remote authority' do
      it 'opens, and explains that its terms are not listed' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/loc/subjects"

        expect(response).to have_http_status(:success)
        expect(response.body).to include 'loc/subjects'
        # Fragments rather than the whole translations: they carry apostrophes, which
        # the body escapes to &#39;, so a literal match would pass vacuously.
        expect(response.body).not_to include 'has no terms yet'
        expect(response.body).to include 'no list to show here'
      end
    end

    # A remote source key carries a slash, which the default :id segment stops at.
    # The url helper escapes it to %2F, so a wrong route yields a link that renders
    # and then 404s rather than failing loudly.
    it 'routes a source key containing a slash' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/loc/iso639-1"

      expect(response).to have_http_status(:success)
      expect(response.body).to include 'loc/iso639-1'
    end

    describe 'a vocabulary whose terms cannot be read' do
      before do
        allow(ControlledVocabularyCatalog).to receive(:file_based_names).and_return(%w[map_regions])
        allow(ControlledVocabularyCatalog).to receive(:terms_for).and_return(nil)
      end

      # nil is "cannot say", not "none": reporting it empty sends staff looking for
      # terms they never added.
      it 'says so instead of claiming it has no terms' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/map_regions"

        expect(response).to have_http_status(:success)
        expect(response.body).to include 'terms cannot be read'
        expect(response.body).not_to include 'has no terms yet'
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

      # A vocabulary cannot be deleted and its source key is fixed at creation, so
      # the values are shown for review before anything is written. The key is
      # derived server-side here, so what the page shows is what gets saved.
      describe 'the confirmation step' do
        it 'shows what will be saved instead of creating straight away' do
          post "http://#{account.cname}/dashboard/controlled_vocabularies",
               params: { param_key => { label: 'Lab Names', description: 'Where the work was done.' } }

          created = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.exists?(name: 'lab_names') }

          expect(response).to have_http_status(:success)
          expect(created).to be false
          expect(response.body).to include 'Lab Names'
          expect(response.body).to include 'lab_names'
          expect(response.body).to include 'Where the work was done.'
        end

        # parameterize transliterates, so an accented label does not yield the key a
        # reader would guess. This is the case the review step earns its keep on.
        it 'shows the transliterated key for an accented name' do
          post "http://#{account.cname}/dashboard/controlled_vocabularies",
               params: { param_key => { label: 'Café Terms' } }

          expect(response.body).to include 'cafe_terms'
        end

        it 'offers a way back to the form without saving' do
          post "http://#{account.cname}/dashboard/controlled_vocabularies",
               params: { param_key => { label: 'Lab Names' } }

          expect(response.body).to include '/dashboard/controlled_vocabularies/new'
        end

        it 'carries the values back without the csrf token' do
          post "http://#{account.cname}/dashboard/controlled_vocabularies",
               params: { param_key => { label: 'Lab Names' } }

          # The link that carries the values, not the breadcrumb to a blank form.
          back = response.body.scan(%r{href="([^"]*controlled_vocabularies/new\?[^"]*)"})
                         .flatten.find { |href| href.include?('local_authority') }

          expect(back).to include 'Lab+Names'
          expect(back).not_to include 'authenticity_token'
        end

        # The way back carries the values with it, so spotting a typo on review does
        # not mean retyping the name and description.
        it 'returns to the form with what was entered still filled in' do
          get "http://#{account.cname}/dashboard/controlled_vocabularies/new",
              params: { param_key => { label: 'Lab Names', description: 'Where the work was done.' } }

          expect(response.body).to include 'Lab Names'
          expect(response.body).to include 'Where the work was done.'
        end

        # The row cannot be deleted once written, so anything short of an actual
        # confirmation has to land on the review step rather than saving.
        it 'reviews rather than saves when the confirmation is empty' do
          post "http://#{account.cname}/dashboard/controlled_vocabularies",
               params: { param_key => { label: 'Lab Names' }, confirmed: '' }

          created = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.exists?(name: 'lab_names') }

          expect(created).to be false
          expect(response).to have_http_status(:success)
        end

        it 'reviews rather than saves when the confirmation says false' do
          post "http://#{account.cname}/dashboard/controlled_vocabularies",
               params: { param_key => { label: 'Lab Names' }, confirmed: 'false' }

          created = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.exists?(name: 'lab_names') }

          expect(created).to be false
          expect(response).to have_http_status(:success)
        end

        # Validation runs before the review, so a name that cannot be saved is
        # reported at once rather than after a confirmation that would fail.
        it 'redisplays the form rather than confirming an invalid vocabulary' do
          post "http://#{account.cname}/dashboard/controlled_vocabularies",
               params: { param_key => { label: 'geonames' } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include 'already in use'
        end
      end

      it 'creates the vocabulary and opens it so terms can be added' do
        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: 'Lab Names', description: 'Where the work was done.' },
                       confirmed: 'true' }

        vocabulary = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.find_by(name: 'lab_names') }

        expect(vocabulary.label).to eq 'Lab Names'
        expect(vocabulary.description).to eq 'Where the work was done.'
        # The app appends a locale param, so match the path rather than the whole url.
        expect(response.location).to include '/dashboard/controlled_vocabularies/lab_names'
      end

      # The review page invites a re-submit, so two confirmations of the same name can
      # race past the validation and collide on the unique index.
      it 'reports a name taken between validation and save' do
        allow_any_instance_of(Qa::LocalAuthority).to receive(:save) # rubocop:disable RSpec/AnyInstance
          .and_raise(ActiveRecord::RecordNotUnique, 'duplicate key value violates unique constraint')

        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: 'Lab Names' }, confirmed: 'true' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include 'lab_names'
      end

      it 'ignores a name supplied in the request' do
        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: 'Lab Names', name: 'something_else' }, confirmed: 'true' }

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

      it 'links the redisplayed breadcrumb to the form, not the listing' do
        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: '' } }

        expect(response.body).to include '/dashboard/controlled_vocabularies/new'
      end

      it 'refuses a duplicate, naming the key already taken' do
        Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.create!(label: 'Café Terms') }

        post "http://#{account.cname}/dashboard/controlled_vocabularies",
             params: { param_key => { label: 'Café Terms' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include 'cafe_terms'
      end
    end

    describe 'adding a term' do
      let(:term_key) { Qa::LocalAuthorityEntry.model_name.param_key }

      it 'saves the term and returns to the vocabulary' do
        Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.create!(label: 'Lab Names') }

        post "http://#{account.cname}/dashboard/controlled_vocabularies/lab_names/terms",
             params: { term_key => { label: 'Wet Lab' } }

        term = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthorityEntry.find_by(label: 'Wet Lab') }

        expect(term).to be_present
        expect(response.location).to include '/dashboard/controlled_vocabularies/lab_names'
      end

      # `ordered` sorts on position, and Postgres puts NULL last — so a term saved
      # without one sorts below every seeded term, and falls off the page entirely in
      # a vocabulary longer than the display limit.
      it 'adds the term after the ones already there' do
        Apartment::Tenant.switch(account.tenant) do
          vocabulary = Qa::LocalAuthority.create!(label: 'Lab Names')
          vocabulary.local_authority_entries.create!(label: 'Wet Lab', uri: 'wet', position: 1)
        end

        post "http://#{account.cname}/dashboard/controlled_vocabularies/lab_names/terms",
             params: { term_key => { label: 'Dry Lab' } }

        labels = Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'lab_names').local_authority_entries.ordered.pluck(:label)
        end

        expect(labels).to eq ['Wet Lab', 'Dry Lab']
      end

      # The case the position fix exists for: rows seeded before positions were
      # assigned hold NULL, which Postgres sorts last — so a naive max+1 gives 1 and
      # the new term jumps to the top of the list instead of the bottom.
      it 'adds the term last even when the existing ones have no position' do
        Apartment::Tenant.switch(account.tenant) do
          vocabulary = Qa::LocalAuthority.create!(label: 'Lab Names')
          vocabulary.local_authority_entries.create!(label: 'Alpha', uri: 'a')
          vocabulary.local_authority_entries.create!(label: 'Beta', uri: 'b')
        end

        post "http://#{account.cname}/dashboard/controlled_vocabularies/lab_names/terms",
             params: { term_key => { label: 'Gamma' } }

        labels = Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'lab_names').local_authority_entries.ordered.pluck(:label)
        end

        expect(labels.last).to eq 'Gamma'
      end

      # An imported copy has a row, so find_by! locates it and the write goes
      # through. The next import then replaces every row, silently discarding the
      # term — the view hides the button, but nothing stops a direct POST.
      it 'refuses a vocabulary whose terms are not this tenant to change' do
        Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.create!(name: 'mesh', label: 'MeSH') }

        post "http://#{account.cname}/dashboard/controlled_vocabularies/mesh/terms",
             params: { term_key => { label: 'Sneaked In' } }

        saved = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthorityEntry.exists?(label: 'Sneaked In') }

        expect(saved).to be false
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'reordering the terms' do
      def term_ids
        Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'reading_rooms').local_authority_entries.ordered.pluck(:id)
        end
      end

      def labels
        Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'reading_rooms').local_authority_entries.ordered.pluck(:label)
        end
      end

      it 'offers the reorder controls on a vocabulary this tenant owns' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

        expect(response.body).to include 'data-term-order-table'
        expect(response.body).to include 'Save order'
      end

      # The order is carried by the sequence of the posted ids, so the page needs no
      # position field to keep in step with the rows.
      it 'posts the term ids rather than a position per term' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

        expect(response.body).to include 'term_ids[]'
      end

      it 'saves the order the terms were left in' do
        reversed = term_ids.reverse

        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/order",
              params: { term_ids: reversed }

        expect(labels).to eq ['Closed Stacks', 'Special Collections']
        expect(response.location).to include '/dashboard/controlled_vocabularies/reading_rooms'
      end

      # A retired term still holds a place in the list, so it has to be reorderable
      # alongside the active ones rather than sinking to the bottom.
      it 'reorders a retired term like any other' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/order",
              params: { term_ids: term_ids.reverse }

        positions = Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'reading_rooms')
                            .local_authority_entries.find_by(label: 'Closed Stacks').position
        end

        expect(positions).to eq 1
      end

      # A vocabulary with one term has no order to set, so the form would be a button
      # that does nothing.
      it 'omits the controls when there is only one term' do
        Apartment::Tenant.switch(account.tenant) do
          vocabulary = Qa::LocalAuthority.create!(label: 'Lab Names')
          vocabulary.local_authority_entries.create!(label: 'Wet Lab', uri: 'wet')
        end

        get "http://#{account.cname}/dashboard/controlled_vocabularies/lab_names"

        expect(response.body).to include 'Wet Lab'
        expect(response.body).not_to include 'data-term-order-table'
      end

      # A yaml vocabulary has no rows to renumber, so its list is read-only however
      # many terms it holds.
      it 'omits the controls on a vocabulary defined in a configuration file' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/resource_types"

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include 'data-term-order-table'
      end

      # The next import replaces every row, so a saved order would be discarded
      # without warning. The view hides the form; nothing stops a direct patch.
      it 'refuses a vocabulary whose terms are not this tenant to change' do
        ids = Apartment::Tenant.switch(account.tenant) do
          vocabulary = Qa::LocalAuthority.create!(name: 'mesh', label: 'MeSH')
          [vocabulary.local_authority_entries.create!(label: 'Anatomy', uri: 'anat').id,
           vocabulary.local_authority_entries.create!(label: 'Biology', uri: 'bio').id]
        end

        patch "http://#{account.cname}/dashboard/controlled_vocabularies/mesh/terms/order",
              params: { term_ids: ids.reverse }

        first = Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'mesh').local_authority_entries.ordered.first.label
        end

        expect(first).to eq 'Anatomy'
        expect(response).to have_http_status(:not_found)
      end

      # Terms belong to the vocabulary in the url, so an id from elsewhere must not be
      # renumbered by posting it here.
      it 'ignores an id belonging to another vocabulary' do
        stranger = Apartment::Tenant.switch(account.tenant) do
          vocabulary = Qa::LocalAuthority.create!(label: 'Lab Names')
          vocabulary.local_authority_entries.create!(label: 'Wet Lab', uri: 'wet', position: 4)
        end

        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/order",
              params: { term_ids: [stranger.id] + term_ids.reverse }

        expect(labels).to eq ['Closed Stacks', 'Special Collections']
        expect(Apartment::Tenant.switch(account.tenant) { stranger.reload.position }).to eq 4
      end

      it 'leaves the order alone when nothing is posted' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/order"

        expect(labels).to eq ['Special Collections', 'Closed Stacks']
      end

      # A hash rather than a list reaches the action as ActionController::Parameters,
      # which is not a number and so is not an id to reorder.
      it 'ignores a posted value that is not an id' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/order",
              params: { term_ids: { 'a' => term_ids.first } }

        expect(response).to have_http_status(:redirect)
        expect(labels).to eq ['Special Collections', 'Closed Stacks']
      end

      # These ids are request data, so a json client can send whatever it likes.
      # `true.to_i` raises where a stray string merely reads as zero.
      it 'ignores json values that are not ids' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/order",
              params: { term_ids: [nil, true, 'abc', term_ids.last] }.to_json,
              headers: { 'CONTENT_TYPE' => 'application/json' }

        expect(response).to have_http_status(:redirect)
        expect(labels).to eq ['Closed Stacks', 'Special Collections']
      end
    end

    describe 'retiring and restoring a term' do
      def term(label)
        Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'reading_rooms').local_authority_entries.find_by(label:)
        end
      end

      it 'offers a toggle against each term' do
        get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

        expect(response.body).to include 'Retire'
        expect(response.body).to include 'Restore'
      end

      it 'retires an active term' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/" \
              "#{term('Special Collections').id}/status",
              params: { active: 'false' }

        expect(term('Special Collections').active).to be false
        expect(response.location).to include '/dashboard/controlled_vocabularies/reading_rooms'
      end

      # Asserted on the rendered text, not just the redirect: the key is interpolated
      # from the direction of the change, so a missing one only shows up on the page.
      it 'says which way the term was moved' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/" \
              "#{term('Special Collections').id}/status",
              params: { active: 'false' }
        follow_redirect!

        expect(response.body).to include 'Special Collections was retired'
        expect(response.body).not_to include 'translation missing'
      end

      it 'restores a retired term' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/" \
              "#{term('Closed Stacks').id}/status",
              params: { active: 'true' }

        expect(term('Closed Stacks').active).to be true
      end

      # Retiring is how a term is taken out of use, because deleting it would orphan
      # every work already citing it. The value has to keep resolving to its label.
      it 'keeps a retired term available to works that already cite it' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/" \
              "#{term('Special Collections').id}/status",
              params: { active: 'false' }

        offered, stored = Apartment::Tenant.switch(account.tenant) do
          service = Hyrax::QaSelectService.new('reading_rooms')
          [service.select_active_options.map(&:first), service.select_all_options.map(&:first)]
        end

        expect(offered).not_to include 'Special Collections'
        expect(stored).to include 'Special Collections'
      end

      # The position is what the order is read from, so retiring must not move the
      # term: restoring it should put it back where it was, not at the end.
      it 'leaves the term where it sits in the order' do
        before_position = term('Special Collections').position

        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/" \
              "#{term('Special Collections').id}/status",
              params: { active: 'false' }

        expect(term('Special Collections').position).to eq before_position
      end

      # Retiring is the destructive direction, so it has to be asked for. Casting a
      # missing parameter reads as false, which would let an incomplete request
      # retire a term nobody named.
      it 'refuses to change a term when no state is given' do
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/" \
              "#{term('Special Collections').id}/status"

        expect(term('Special Collections').active).to be true
        expect(response).to have_http_status(:bad_request)
      end

      # A term belongs to the vocabulary in the url, so one from elsewhere must not be
      # reachable by posting its id here.
      it 'refuses a term belonging to another vocabulary' do
        stranger = Apartment::Tenant.switch(account.tenant) do
          vocabulary = Qa::LocalAuthority.create!(label: 'Lab Names')
          vocabulary.local_authority_entries.create!(label: 'Wet Lab', uri: 'wet')
        end

        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/" \
              "#{stranger.id}/status",
              params: { active: 'false' }

        expect(Apartment::Tenant.switch(account.tenant) { stranger.reload.active }).to be true
        expect(response).to have_http_status(:not_found)
      end

      # The next import replaces every row, so a retirement would be silently undone.
      it 'refuses a vocabulary whose terms are not this tenant to change' do
        mesh_term = Apartment::Tenant.switch(account.tenant) do
          vocabulary = Qa::LocalAuthority.create!(name: 'mesh', label: 'MeSH')
          vocabulary.local_authority_entries.create!(label: 'Anatomy', uri: 'anat')
        end

        patch "http://#{account.cname}/dashboard/controlled_vocabularies/mesh/terms/#{mesh_term.id}/status",
              params: { active: 'false' }

        expect(Apartment::Tenant.switch(account.tenant) { mesh_term.reload.active }).to be true
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'as a user with no deposit access' do
    before do
      user = Apartment::Tenant.switch(account.tenant) { create(:user) }
      login_as(user, scope: :user)
    end

    it 'refuses a download' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms.csv"

      expect(response).not_to have_http_status(:success)
      expect(response.headers['Content-Disposition']).to be_nil
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
           params: { param_key => { label: 'Lab Names' }, confirmed: 'true' }

      created = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthority.exists?(name: 'lab_names') }

      expect(created).to be false
    end

    it 'lists the terms without the reorder controls' do
      get "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms"

      expect(response).to have_http_status(:success)
      expect(response.body).to include 'Special Collections'
      expect(response.body).not_to include 'data-term-order-table'
    end

    it 'refuses to retire a term' do
      id = Apartment::Tenant.switch(account.tenant) do
        Qa::LocalAuthority.find_by(name: 'reading_rooms').local_authority_entries.find_by(label: 'Special Collections').id
      end

      patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/#{id}/status",
            params: { active: 'false' }

      active = Apartment::Tenant.switch(account.tenant) { Qa::LocalAuthorityEntry.find(id).active }

      expect(active).to be true
    end

    it 'refuses the reorder' do
      ids = Apartment::Tenant.switch(account.tenant) do
        Qa::LocalAuthority.find_by(name: 'reading_rooms').local_authority_entries.ordered.pluck(:id)
      end

      patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/order",
            params: { term_ids: ids.reverse }

      labels = Apartment::Tenant.switch(account.tenant) do
        Qa::LocalAuthority.find_by(name: 'reading_rooms').local_authority_entries.ordered.pluck(:label)
      end

      expect(labels).to eq ['Special Collections', 'Closed Stacks']
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
