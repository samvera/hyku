# frozen_string_literal: true

RSpec.describe CatalogController do
  # Hyku solr/conf/solrconfig.xml does not define per-field spellcheck dictionaries
  # (e.g. creator, publisher); sending them caused Solr errors / Blacklight InvalidRequest.
  describe "search field Solr params (spellcheck regression)" do
    %w[
      contributor
      creator
      title
      description
      publisher
      date_created
      subject
      language
      resource_type
      format
      identifier
      based_near_label
      keyword
    ].each do |key|
      it "does not set spellcheck.dictionary on #{key} search field" do
        field = described_class.blacklight_config.search_fields[key]
        expect(field).to be_present, "expected search_fields['#{key}'] to exist"
        solr_keys = (field.solr_parameters || {}).stringify_keys.keys
        expect(solr_keys).not_to include("spellcheck.dictionary")
      end
    end
  end

  describe "GET /show" do
    let(:file_set) { create(:file_set) }

    context "with access" do
      before do
        sign_in create(:user)
        allow(controller).to receive(:can?).and_return(true)
      end

      it "is successful" do
        get :show, params: { id: file_set }
        expect(response).to be_successful
        expect(response.content_type).to eq "application/json; charset=utf-8"
      end
    end

    context "without access" do
      it "is redirects to sign in" do
        get :show, params: { id: file_set }
        expect(response).to redirect_to new_user_session_path
      end
    end
  end
  describe 'memoization isolation' do
    after do
      allow(Site).to receive(:instance).and_call_original
    end

    let(:role_name) { RolesService::DEFAULT_ROLES.first } # "admin"
    let(:site_one) { FactoryBot.create(:site, application_name: "Site One") }
    let(:site_two) { FactoryBot.create(:site, application_name: "Site Two") }
    let(:user) { FactoryBot.create(:user) }

    describe 'multi-tenancy: memo does not bleed across site switches' do
      it 're-evaluates the role check after Site.instance changes within the same Ability instance' do
        user.add_role(role_name, site_one)
        ability = Ability.new(user)

        allow(Site).to receive(:instance).and_return(site_one)
        # Warm the cache under site_one — user has the role here
        expect(ability.public_send("#{role_name}?")).to be true

        # Simulate a tenant switch on the same Ability instance
        allow(Site).to receive(:instance).and_return(site_two)
        # The cache key includes site_instance.id, so this must re-evaluate.
        expect(ability.public_send("#{role_name}?")).to be false
      end
    end
    it 'scopes memoization for group_role_memo to the Ability instance lifetime' do
      sign_in create(:admin)

      get :index
      first_ability = controller.current_ability
      first_ability.admin? # populate the memoization
      first_cache = first_ability.instance_variable_get(:@group_role_memo)
      expect(first_cache).not_to be_empty

      get :index
      second_ability = controller.current_ability
      second_ability.admin? # populate the memoization on the new instance
      second_cache = second_ability.instance_variable_get(:@group_role_memo)
      expect(second_cache).not_to be_empty

      expect(first_ability.object_id).not_to eq(second_ability.object_id)

      # Become a regular user - session should not persist
      sign_in create(:user, display_name: "Regular user")

      get :index
      third_ability = controller.current_ability
      expect(third_ability.admin?).to be false # populate the memoization on the new instance
      third_cache = third_ability.instance_variable_get(:@group_role_memo)
      site_id = Site.instance.id
      admin_role = RolesService::ADMIN_ROLE
      expect(second_cache[[admin_role, site_id, second_ability.current_user.id]]).to be true
      expect(third_cache[[admin_role, site_id, third_ability.current_user.id]]).to be false
      expect(second_cache).not_to eq(third_cache)
    end
  end
end
