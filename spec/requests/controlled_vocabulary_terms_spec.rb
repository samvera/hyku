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

    it 'links the redisplayed breadcrumb to the form, not the post path' do
      post "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms",
           params: { param_key => { label: '' } }

      expect(response.body).to include '/dashboard/controlled_vocabularies/reading_rooms/terms/new'
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

    describe 'reordering terms' do
      def create_terms
        Apartment::Tenant.switch(account.tenant) do
          vocab = Qa::LocalAuthority.find_by(name: 'reading_rooms')
          %w[Alpha Beta].map { |label| vocab.local_authority_entries.create!(label: label, uri: label.downcase).id }
        end
      end

      def digest
        Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'reading_rooms').term_state_digest
        end
      end

      def patch_order(ids, state_digest)
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/order",
              params: { term_ids: ids, state_digest: state_digest }
      end

      it 'saves the order the page was drawn from' do
        alpha, beta = create_terms

        patch_order([beta, alpha], digest)

        expect(terms_in('reading_rooms').sort_by(&:position).map(&:label)).to eq %w[Beta Alpha]
      end

      # Someone else reordered between this page being drawn and its save.
      it 'refuses an order built on terms that have since changed' do
        alpha, beta = create_terms
        stale = digest
        patch_order([beta, alpha], stale)

        patch_order([alpha, beta], stale)

        expect(flash[:alert]).to eq I18n.t('hyku.admin.controlled_vocabulary.order_stale')
        expect(terms_in('reading_rooms').sort_by(&:position).map(&:label)).to eq %w[Beta Alpha]
      end
    end

    describe 'changing a term status' do
      def create_term
        Apartment::Tenant.switch(account.tenant) do
          Qa::LocalAuthority.find_by(name: 'reading_rooms')
                            .local_authority_entries.create!(label: 'Rare Books', uri: 'rare-books').id
        end
      end

      def patch_status(id, active)
        patch "http://#{account.cname}/dashboard/controlled_vocabularies/reading_rooms/terms/#{id}/status",
              params: { active: active }
      end

      it 'retires the term' do
        patch_status(create_term, 'false')

        expect(terms_in('reading_rooms').first.active).to be false
      end

      it 'restores the term' do
        id = create_term
        patch_status(id, 'false')
        patch_status(id, 'true')

        expect(terms_in('reading_rooms').first.active).to be true
      end

      # Casting alone reads any non-empty string as true, so an unrecognized value
      # would restore a retired term rather than being refused.
      it 'refuses a value that is not a boolean' do
        id = create_term
        patch_status(id, 'false')

        patch_status(id, 'garbage')

        expect(response).to have_http_status(:bad_request)
        expect(terms_in('reading_rooms').first.active).to be false
      end
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
