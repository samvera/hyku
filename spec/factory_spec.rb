# frozen_string_literal: true

RSpec.describe "Factories" do
  before { Hyrax::Group.find_or_create_by!(name: ::Ability.admin_group_name) }

  describe ':generic_work_resource' do
    context 'without being indexed' do
      # Maybe you don't need to index the document; for speed purposes.
      it 'exists in the metadata storage but not the index' do
        resource = FactoryBot.valkyrie_create(:generic_work_resource, with_index: false)
        expect(Hyrax.query_service.find_by(id: resource.id)).to be_a(GenericWorkResource)

        expect(Hyrax::SolrService.query("id:#{resource.id}")).to be_empty
      end
    end
    context 'without an admin set' do
      it 'creates a resource that is indexed' do
        resource = FactoryBot.valkyrie_create(:generic_work_resource)
        expect(GenericWorkResource.find_by(id: resource.id)).to be_a(GenericWorkResource)

        expect(Hyrax::SolrService.query("id:#{resource.id}").map(&:id)).to match_array([resource.id.to_s])
      end
    end

    context 'with an admin set' do
      let(:depositor) { FactoryBot.create(:user, roles: [:work_depositor]) }
      let(:visibility_setting) { 'open' }
      it 'creates a resource' do
        # Do this before we create the admin set.
        resource = FactoryBot.valkyrie_create(:generic_work_resource, :with_default_admin_set, depositor: depositor.user_key, visibility_setting:)
        expect(GenericWorkResource.find(resource.id)).to be_a(GenericWorkResource)
      end
    end

    context 'as collection member' do
      let(:visibility_setting) { 'open' }
      it 'creates a resource that is part of the collection' do
        collection = FactoryBot.valkyrie_create(:hyku_collection)
        resource = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting:)

        expect(Hyrax.query_service.custom_queries.find_collections_for(resource:)).to match_array([collection])
        expect(Hyrax.query_service.custom_queries.find_members_of(collection:)).to match_array([resource])
      end
    end
  end

  describe ':hyku_admin_set' do
    let(:klass) { Hyrax.config.admin_set_class }
    it 'is an AdminSetResource' do
      expect(FactoryBot.build(:hyku_admin_set)).to be_a_kind_of(klass)
    end

    it "creates an admin set and can create it's permission template" do
      expect do
        admin_set = FactoryBot.valkyrie_create(:hyku_admin_set, with_permission_template: true)
        expect(admin_set.permission_template).to be_a(Hyrax::PermissionTemplate)
        # It cannot create workflows
        expect(admin_set.permission_template.available_workflows).not_to be_present
      end.to change { Hyrax.query_service.count_all_of_model(model: klass) }.by(1)
    end
  end

  describe ':hyku_collection and progeny' do
    let(:klass) { Hyrax.config.collection_class }

    it 'creates a collection that is by default private' do
      collection = FactoryBot.valkyrie_create(:hyku_collection)
      expect(collection).to be_a(klass)
      expect(collection).not_to be_public
      expect(collection).to be_private
    end

    it 'creates a public collection when specified' do
      collection = FactoryBot.valkyrie_create(:hyku_collection, :public)
      expect(collection).to be_a(klass)
      expect(collection).to be_public
      expect(collection).not_to be_private
    end

    it 'creates correct permissions' do
      user = FactoryBot.create(:user)
      role = FactoryBot.create(:role, :collection_editor)
      user.add_role(role.name, Site.instance)

      ability = Ability.new(user)

      collection = FactoryBot.valkyrie_create(:hyku_collection)
      require 'byebug'; byebug

      expect(ability.can? :create, Hyrax.config.collection_class).to be_truthy

      # There will be direct checks on the object
      expect(ability.can? :show, collection).to be_truthy
      expect(ability.can? :edit, collection).to be_truthy

      # And there are checks on the solr document; which is done by looking at the ID.
      expect(ability.can? :show, collection.id).to be_truthy
      expect(ability.can? :edit, collection.id).to be_truthy
    end
  end
end
