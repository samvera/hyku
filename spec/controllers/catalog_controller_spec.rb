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
      tenant = Apartment::Tenant.current
      admin_role = RolesService::ADMIN_ROLE
      expect(second_cache[[admin_role, tenant, site_id, second_ability.current_user.id]]).to be true
      expect(third_cache[[admin_role, tenant, site_id, third_ability.current_user.id]]).to be false
      expect(second_cache).not_to eq(third_cache)
    end
  end

  describe '.search_result_fields' do
    let(:full_text_fields) { %w[all_text_tsimv] }
    let(:globs) { described_class.search_result_fields(full_text_fields).split(',') - ['score'] }
    let(:stored_schema_fields) do
      schema = Nokogiri::XML(File.read(Rails.root.join('solr', 'conf', 'schema.xml')))
      stored_types = schema.xpath('//fieldType').reject { |type| type['stored'] == 'false' }.map { |type| type['name'] }
      schema.xpath('//field | //dynamicField')
            .select { |field| field['stored'] == 'true' || (field['stored'].nil? && stored_types.include?(field['type'])) }
            .map { |field| field['name'] }
    end

    def returned?(name)
      globs.any? { |glob| File.fnmatch(glob, name) }
    end

    it 'returns every stored field in the schema except the stored full text' do
      expect(stored_schema_fields - ['*_tsimv']).to all(satisfy { |name| returned?(name) })
    end

    it 'does not return the stored full text' do
      expect(returned?('all_text_tsimv')).to be(false)
    end

    context 'with a legacy full-text field under another suffix' do
      let(:full_text_fields) { %w[all_text_tsimv all_text_tesimv] }

      it 'does not return either full-text field' do
        expect(%w[all_text_tsimv all_text_tesimv].map { |name| returned?(name) }).to eq([false, false])
      end
    end

    it 'is what catalog searches ask Solr to return' do
      expect(described_class.blacklight_config.default_solr_params[:fl]).to eq(described_class.search_result_fields)
    end
  end

  describe '.add_full_text_index_fields' do
    let(:config) { Blacklight::Configuration.new }

    it 'renders snippets for every configured full-text field' do
      described_class.add_full_text_index_fields(config, %w[all_text_tsimv file_set_text_tsimv])

      expect(config.index_fields.values.map { |field| [field.field, field.highlight, field.helper_method] })
        .to eq([['all_text_tsimv', true, :render_ocr_snippets], ['file_set_text_tsimv', true, :render_ocr_snippets]])
    end
  end

  describe 'full-text keyword search' do
    let(:config) { described_class.blacklight_config }

    it 'searches every configured full-text field' do
      qfs = [config.default_solr_params[:qf], config.search_fields['all_fields'].solr_parameters[:qf]].map(&:split)

      expect(qfs).to all(include(*Hyku::Application.full_text_fields))
    end
  end
end
