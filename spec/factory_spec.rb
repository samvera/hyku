# frozen_string_literal: true

RSpec.describe "Factories", clean: true do
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
      let(:admin_set) { FactoryBot.valkyrie_create(:hyku_admin_set, title: ['Test Admin Set'], with_permission_template: { with_workflows: true }) }
      let(:resource) { FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, depositor: depositor.user_key, visibility_setting:, admin_set:) }
      context 'with open visibility' do
        let(:visibility_setting) { 'open' }

        it 'creates a resource with correct permissions' do
          # Do this before we create the admin set.

          expect(GenericWorkResource.find(resource.id)).to be_a(GenericWorkResource)
          template = Hyrax::PermissionTemplate.find_by!(source_id: admin_set.id)
          expect(Sipity::Entity(resource)).to be_a(Sipity::Entity)
          expect(resource.permission_manager.edit_groups.to_a).to include(*template.agent_ids_for(agent_type: 'group', access: 'manage'))

          # Because we have a public work, the template's agent is obliterated.
          expect(resource.permission_manager.read_groups.to_a).not_to include(*template.agent_ids_for(agent_type: 'group', access: 'view'))
          expect(resource.permission_manager.read_groups.to_a).to include("public")
        end
      end

      context 'with restricted visibility' do
        let(:visibility_setting) { 'authenticated' }

        it 'creates a resource with correct permissions' do
          # Do this before we create the admin set.

          expect(GenericWorkResource.find(resource.id)).to be_a(GenericWorkResource)
          expect(Sipity::Entity(resource)).to be_a(Sipity::Entity)
          template = Hyrax::PermissionTemplate.find_by!(source_id: admin_set.id)

          expect(resource.permission_manager.edit_groups.to_a).to include(*template.agent_ids_for(agent_type: 'group', access: 'manage'))

          # TODO: There's a larger problem of the permission templates not being correctly
          # applied via the RoleService.  I suspect there's something configurable in Hyrax that's
          # creating some mayhem.  expect(resource.permission_manager.read_groups.to_a).to

          # include(*template.agent_ids_for(agent_type: 'group', access: 'view'))
          expect(resource.permission_manager.read_groups.to_a).not_to include("public")
        end
      end
    end

    context 'as collection member' do
      let(:visibility_setting) { 'open' }
      it 'creates a resource that is part of the collection' do
        collection = FactoryBot.valkyrie_create(:hyku_collection)
        expect(collection).to be_a(CollectionResource)
        resource = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting:)

        expect(Hyrax.query_service.custom_queries.find_collections_for(resource:)).to match_array([collection])
        expect(Hyrax.query_service.custom_queries.find_members_of(collection:)).to match_array([resource])
      end
    end
  end

  describe ':hyrax_admin_set' do
    it 'is an AdminSetResource' do
      expect(Hyrax.config.admin_set_class).to eq(AdminSetResource)
      expect(FactoryBot.build(:hyrax_admin_set)).to be_a_kind_of(AdminSetResource)
    end

    it 'can create a permission template and active workflow' do
      expect do
        expect do
          expect do
            FactoryBot.valkyrie_create(:hyku_admin_set, title: ['Test Admin Set'], with_permission_template: { with_workflows: true })
          end.to change { Hyrax.query_service.count_all_of_model(model: AdminSetResource) }.by(1)
        end.to change { Hyrax::PermissionTemplate.count }.by(1)
      end.to change { Sipity::Workflow.count }.from(0) # We'll create at least one
      permission_template = Hyrax::PermissionTemplate.last
      expect(permission_template.active_workflow).to be_present
    end
  end

  describe ':hyku_admin_set' do
    it 'is an AdminSetResource' do
      expect(Hyrax.config.admin_set_class).to eq(AdminSetResource)
      expect(FactoryBot.build(:hyku_admin_set)).to be_a_kind_of(AdminSetResource)
    end

    it "creates an admin set and can create it's permission template" do
      expect do
        admin_set = FactoryBot.valkyrie_create(:hyku_admin_set, with_permission_template: true)
        expect(admin_set.permission_template).to be_a(Hyrax::PermissionTemplate)
        # It cannot create workflows
        expect(admin_set.permission_template.available_workflows).not_to be_present
      end.to change { Hyrax.query_service.count_all_of_model(model: AdminSetResource) }.by(1)
    end
  end

  describe ':hyku_collection and progeny' do
    let(:klass) { Hyrax.config.collection_class }

    it 'is part of a collection type', ci: 'skip' do
      collection_type = FactoryBot.create(:collection_type, title: 'Not Empty Type')
      collection = FactoryBot.valkyrie_create(:hyku_collection, collection_type_gid: collection_type.to_global_id.to_s)

      collection_ids = Hyrax::SolrService.query("#{Hyrax.config.collection_type_index_field.to_sym}:\"#{collection_type.to_global_id}\"").map(&:id)
      expect(collection_ids).to match_array([collection.id.to_s])
      expect(collection.collection_type).to eq(collection_type)

      expect(collection_type.collections.to_a).to match_array([collection])
    end

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

      expect(ability.can?(:create, Hyrax.config.collection_class)).to be_truthy

      # There will be direct checks on the object
      expect(ability.can?(:show, collection)).to be_truthy
      expect(ability.can?(:edit, collection)).to be_truthy

      # And there are checks on the solr document; which is done by looking at the ID.
      expect(ability.can?(:show, collection.id)).to be_truthy
      expect(ability.can?(:edit, collection.id)).to be_truthy
    end
  end

  describe ':permission_template' do
    it 'creates the permission template and can create workflows and a corresponding admin_set', ci: 'skip' do
      # The permission template is defined in Hyrax.  It should be creating an object of the correct
      # configuration.
      permission_template = FactoryBot.create(:permission_template, with_admin_set: true, with_workflows: true)
      expect(permission_template.source).to be_a AdminSetResource # A bit of hard-coding to see about snaring a bug.
      expect(permission_template.active_workflow).to be_present
      expect(permission_template.source).to be_a Hyrax.config.admin_set_class
    end
  end
end
