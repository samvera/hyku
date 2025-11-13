# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RolesService, clean: true do
  subject(:roles_service) { described_class }
  let(:admin_group) { FactoryBot.create(:admin_group) }
  let(:default_role_count) { described_class::DEFAULT_ROLES.count }
  let(:default_hyrax_group_count) { described_class::DEFAULT_HYRAX_GROUPS_WITH_ATTRIBUTES.keys.count }

  shared_examples 'must run inside a tenant' do |method_to_run, scope_warning|
    context 'when run outside the scope of a tenant' do
      let(:scope_warning) { scope_warning }

      before { allow(Site).to receive(:instance).and_return(NilSite.new) }
      after { allow(Site).to receive(:instance).and_call_original } # un-stub Site

      it 'returns a warning' do
        expect(roles_service.public_send(method_to_run)).to eq(scope_warning)
      end
    end
  end

  describe '#find_or_create_site_role!' do
    let(:test_role_name) { 'test_role' }

    it 'requires a :role_name argument' do
      expect { roles_service.find_or_create_site_role! }
        .to raise_error(ArgumentError, 'missing keyword: :role_name')
    end

    it 'returns the role' do
      expect(roles_service.find_or_create_site_role!(role_name: test_role_name))
        .to be_an_instance_of(Role)
    end

    context 'when the role does not exist' do
      it 'creates a role' do
        expect { roles_service.find_or_create_site_role!(role_name: test_role_name) }
          .to change(Role, :count).by(1)
      end
    end

    context 'when the role already exists' do
      before do
        Role.find_or_create_by!(
          name: test_role_name,
          resource_id: Site.instance.id,
          resource_type: 'Site'
        )
      end

      it 'does not create a role' do
        expect { roles_service.find_or_create_site_role!(role_name: test_role_name) }
          .to change(Role, :count).by(0)
      end

      it 'finds the site role' do
        expect(roles_service.find_or_create_site_role!(role_name: test_role_name))
          .to eq(Role.last)
      end
    end
  end

  describe '#create_default_roles!' do
    include_examples 'must run inside a tenant',
                     :create_default_roles!,
                     '`AccountElevator.switch!` into an Account before creating default Roles'

    context 'when run inside the scope of a tenant' do
      it 'creates all default roles' do
        expect { roles_service.create_default_roles! }
          .to change(Role, :count).by(default_role_count)
      end

      # rubocop:disable RSpec/SubjectStub
      it 'calls #find_or_create_site_role! for each role' do
        expect(roles_service)
          .to receive(:find_or_create_site_role!)
          .exactly(default_role_count).times

        roles_service.create_default_roles!
      end
      # rubocop:enable RSpec/SubjectStub
    end
  end

  describe '#create_default_hyrax_groups_with_roles!' do
    include_examples 'must run inside a tenant',
                     :create_default_hyrax_groups_with_roles!,
                     '`AccountElevator.switch!` into an Account before creating default Hyrax::Groups'

    context 'when run inside the scope of a tenant' do
      it 'creates all default hyrax groups with their default roles' do
        expect { roles_service.create_default_hyrax_groups_with_roles! }
          .to change(Hyrax::Group, :count).by(default_hyrax_group_count)
      end

      it 'creates the admin group' do
        roles_service.create_default_hyrax_groups_with_roles!

        admin_group = Hyrax::Group.find_by(name: 'admin')
        expect(admin_group.humanized_name).to eq('Repository Administrators')
        expect(admin_group.description).to eq(I18n.t("hyku.admin.groups.description.#{::Ability.admin_group_name}"))
        expect(admin_group.roles.map(&:name)).to contain_exactly('admin')
      end

      it 'creates the registered group' do
        roles_service.create_default_hyrax_groups_with_roles!

        registered_group = Hyrax::Group.find_by(name: 'registered')
        expect(registered_group.humanized_name).to eq('Registered Users')
        expect(registered_group.description).to eq(
          I18n.t(
            "hyku.admin.groups.description.#{::Ability.registered_group_name}"
          )
        )
        expect(registered_group.roles.map(&:name)).to eq([])
      end

      it 'creates the tenant editors group' do
        roles_service.create_default_hyrax_groups_with_roles!

        editors_group = Hyrax::Group.find_by(name: 'editors')
        expect(editors_group.humanized_name).to eq('Editors')
        expect(editors_group.description).to eq(I18n.t('hyku.admin.groups.description.editors'))
        expect(editors_group.roles.map(&:name)).to contain_exactly('collection_editor', 'work_editor', 'user_reader')
      end

      it 'creates the tenant depositors group' do
        roles_service.create_default_hyrax_groups_with_roles!

        depositors_group = Hyrax::Group.find_by(name: 'depositors')
        expect(depositors_group.humanized_name).to eq('Depositors')
        expect(depositors_group.description).to eq(I18n.t('hyku.admin.groups.description.depositors'))
        expect(depositors_group.roles.map(&:name)).to contain_exactly('work_depositor')
      end
    end
  end

  describe '#create_collection_accesses!' do
    let(:permission_template) { FactoryBot.create(:permission_template, source_id: collection.id) }
    let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }

    context 'when a Collection already has PermissionTemplateAccess records for all of the collection roles' do
      # The ##create_collection_accesses! method also grants the admin group manage access.
      # This does not happen on permission template creation by default, so we simulate it here.
      before do
        admin_group # We need to create this creature for this spec
        collection.permission_template.access_grants.find_or_create_by!(
          access: Hyrax::PermissionTemplateAccess::MANAGE,
          agent_type: Hyrax::PermissionTemplateAccess::GROUP,
          agent_id: Ability.admin_group_name
        )
      end

      it 'does not create any new PermissionTemplateAccess records' do
        expect { roles_service.create_collection_accesses! }
          .not_to change(Hyrax::PermissionTemplateAccess, :count)
      end

      it "does not reset the Collection's access controls unnecessarily" do
        expect_any_instance_of(Hyrax::PermissionTemplate).not_to receive(:reset_access_controls_for)

        roles_service.create_collection_accesses!
      end
    end

    context 'when a Collection does not have access records for the collection roles' do
      before do
        collection.permission_template.access_grants.map(&:destroy)
      end

      it 'creates a PermissionTemplateAccess record for the three collection roles and one admin role' do
        expect { roles_service.create_collection_accesses! }
          .to change(Hyrax::PermissionTemplateAccess, :count)
          .by(4)
      end

      it 'creates a PermissionTemplateAccess record with MANAGE access for the :collection_manager role' do
        expect { roles_service.create_collection_accesses! }
          .to change { access_count_for('collection_manager', collection.permission_template, Hyrax::PermissionTemplateAccess::MANAGE) }
          .from(0).to(1)
      end

      it 'creates a PermissionTemplateAccess record with VIEW access for the :collection_editor role' do
        expect { roles_service.create_collection_accesses! }
          .to change { access_count_for('collection_editor', collection.permission_template, Hyrax::PermissionTemplateAccess::VIEW) }
          .from(0).to(1)
      end

      it 'creates a PermissionTemplateAccess record with VIEW access for the :collection_reader role' do
        expect { roles_service.create_collection_accesses! }
          .to change { access_count_for('collection_reader', collection.permission_template, Hyrax::PermissionTemplateAccess::VIEW) }
          .from(0).to(1)
      end

      it "resets the Collection's access controls" do
        expect_any_instance_of(Hyrax::PermissionTemplate).to receive(:reset_access_controls_for).once

        roles_service.create_collection_accesses!
      end
    end
  end

  describe '#create_admin_set_accesses!' do
    let!(:permission_template) { FactoryBot.create(:permission_template, with_admin_set: true, source_id: admin_set.id) }
    let(:admin_set) { FactoryBot.valkyrie_create(:hyku_admin_set) }

    context 'when an AdminSet already has PermissionTemplateAccess records for all of the work roles' do
      it 'does not create any new PermissionTemplateAccess records' do
        expect { roles_service.create_admin_set_accesses! }
          .not_to change { permission_template.access_grants.count }
      end

      it "does not reset the AdminSet's access controls unnecessarily" do
        expect_any_instance_of(Hyrax::PermissionTemplate).not_to receive(:reset_access_controls_for)

        roles_service.create_admin_set_accesses!
      end
    end

    context 'when an AdminSet does not have access records for the work roles' do
      before do
        permission_template.access_grants.destroy_all
      end

      it 'creates four new PermissionTemplateAccess records' do
        expect { roles_service.create_admin_set_accesses! }
          .to change(Hyrax::PermissionTemplateAccess, :count)
          .by(4)
      end

      it 'creates a PermissionTemplateAccess record with MANAGE access for the admin group' do
        expect { roles_service.create_admin_set_accesses! }
          .to change { access_count_for(Ability.admin_group_name, permission_template, Hyrax::PermissionTemplateAccess::MANAGE) }
          .from(0).to(1)
      end

      it 'creates a PermissionTemplateAccess record with DEPOSIT access for the :work_editor role' do
        expect { roles_service.create_admin_set_accesses! }
          .to change { access_count_for('work_editor', permission_template, Hyrax::PermissionTemplateAccess::DEPOSIT) }
          .from(0).to(1)
      end

      it 'creates a PermissionTemplateAccess record with DEPOSIT access for the :work_depositor role' do
        expect { roles_service.create_admin_set_accesses! }
          .to change { access_count_for('work_depositor', permission_template, Hyrax::PermissionTemplateAccess::DEPOSIT) }
          .from(0).to(1)
      end

      it 'creates a PermissionTemplateAccess record with VIEW access for the :work_editor role' do
        expect { roles_service.create_admin_set_accesses! }
          .to change { access_count_for('work_editor', permission_template, Hyrax::PermissionTemplateAccess::VIEW) }
          .from(0).to(1)
      end

      it "resets the AdminSet's access controls" do
        expect_any_instance_of(Hyrax::PermissionTemplate).to receive(:reset_access_controls_for).once

        roles_service.create_admin_set_accesses!
      end
    end
  end

  describe '#create_collection_type_participants!' do
    context 'when the collection type already has participants for the collection roles' do
      # All non-AdminSet CollectionTypes created through the UI should automatically
      # get the :collection_manager role as a group participant with manage access
      # and the :collection_editor role as a group participant with create access
      before do
        FactoryBot.create(:collection_type)
      end

      it 'does not create any new CollectionTypeParticipant records' do
        expect { roles_service.create_collection_type_participants! }
          .not_to change(Hyrax::CollectionTypeParticipant, :count)
      end
    end

    context 'when the collection type does not have participants for the collection roles' do
      let!(:collection_type) { FactoryBot.create(:collection_type, :without_default_participants) }

      it 'creates two CollectionTypeParticipant records' do
        expect { roles_service.create_collection_type_participants! }
          .to change(Hyrax::CollectionTypeParticipant, :count)
          .by(2)
      end

      it 'creates a CollectionTypeParticipant record with MANAGE_ACCESS for the :collection_manager role' do
        expect { roles_service.create_collection_type_participants! }
          .to change {
                collection_type.collection_type_participants.where(
                agent_id: 'collection_manager',
                agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS
              ).count
              }.from(0).to(1)
      end

      it 'creates a CollectionTypeParticipant record with CREATE_ACCESS for the :collection_editor role' do
        expect { roles_service.create_collection_type_participants! }
          .to change {
                collection_type.collection_type_participants.where(
                agent_id: 'collection_editor',
                agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS
              ).count
              }.from(0).to(1)
      end
    end

    context 'when the collection type is the admin set' do
      before do
        FactoryBot.create(:admin_set_collection_type)
      end

      it 'does not create any CollectionTypeParticipant records for the collection roles' do
        expect { roles_service.create_collection_type_participants! }
          .not_to change(Hyrax::CollectionTypeParticipant, :count)
      end
    end
  end

  describe '#destroy_registered_group_collection_type_participants!' do
    context 'when multiple CollectionTypes grant the registered group create access' do
      before do
        FactoryBot.create(:collection_type, creator_group: ::Ability.registered_group_name)
        FactoryBot.create(:collection_type, creator_group: ::Ability.registered_group_name)
        FactoryBot.create(:collection_type, creator_group: ::Ability.registered_group_name)
      end

      it 'destroys all CollectionTypeParticipant records that grant the registered group create access' do
        expect { roles_service.destroy_registered_group_collection_type_participants! }
          .to change(Hyrax::CollectionTypeParticipant, :count).by(-3)
      end
    end

    context 'when CollectionTypes grant access to other users/groups' do
      before do
        creator_user = FactoryBot.create(:user)
        FactoryBot.create(:collection_type, creator_user:)
        FactoryBot.create(:collection_type, creator_group: 'Test Group')
        FactoryBot.create(:collection_type, manager_group: ::Ability.admin_group_name)
        FactoryBot.create(:collection_type, manager_group: ::Ability.registered_group_name)
      end

      it 'does not destroy CollectionTypeParticipant records that do not grant the registered group create access' do
        expect { roles_service.destroy_registered_group_collection_type_participants! }
          .not_to change(Hyrax::CollectionTypeParticipant, :count)
      end
    end
  end

  describe '#create_admin_group_memberships!' do
    let(:registered_group) { Hyrax::Group.find_by(name: Ability.registered_group_name) }

    context 'when a user has the admin role' do
      let!(:user) { create(:admin) }

      it 'adds that user to the admin group' do
        expect(admin_group.members).to be_empty

        roles_service.create_admin_group_memberships!

        expect(admin_group.members).to include(user)
      end

      it 'adds that user to the registered group' do
        # Users created within the scope of a tenant will automatically become members
        # of the registered group (@see User#add_default_group_membership!). To
        # effectively test this method, we need to remove the user first.
        registered_group.remove_members_by_id(user.id)
        expect(registered_group.members).to be_empty

        roles_service.create_admin_group_memberships!

        expect(registered_group.members).to include(user)
      end
    end

    context 'when a user does not have the admin role' do
      let!(:user) { create(:user) }

      it 'does not add that user to the admin group' do
        expect(admin_group.members).to be_empty

        roles_service.create_admin_group_memberships!

        expect(admin_group.members).not_to include(user)
      end

      it 'does not add that user to the registered group' do
        # Users created within the scope of a tenant will automatically become members
        # of the registered group (@see User#add_default_group_membership!). To
        # effectively test this method, we need to remove the user first.
        registered_group.remove_members_by_id(user.id)
        expect(registered_group.members).to be_empty

        roles_service.create_admin_group_memberships!

        expect(registered_group.members).not_to include(user)
      end
    end
  end

  describe '#prune_stale_guest_users' do
    before do
      3.times do |i|
        u = FactoryBot.create(:user)
        u.update!(updated_at: (i + 6).days.ago)
      end
    end

    it 'does not delete non-guest users' do
      expect { roles_service.prune_stale_guest_users }
        .not_to change(User.unscoped, :count)
    end

    context 'when there are guest users that have not been updated in over 7 days' do
      before do
        3.times do
          FactoryBot.create(:guest_user, stale: true)
        end
      end

      it 'deletes them' do
        expect { roles_service.prune_stale_guest_users }
          .to change(User.unscoped, :count).by(-3)
      end
    end

    context 'when there are guest users that have been updated in the last 7 days' do
      before do
        3.times do
          FactoryBot.create(:guest_user)
        end
      end

      it 'does not delete them' do
        expect { roles_service.prune_stale_guest_users }
          .not_to change(User.unscoped, :count)
      end
    end
  end

  describe '#grant_workflow_roles_for_all_admin_sets!' do
    before do
      3.times do
        FactoryBot.create(:hyku_admin_set, with_permission_template: true)
      end
    end

    it 'calls Hyrax::Workflow::PermissionGrantor#grant_default_workflow_roles!' do
      expect(Hyrax::Workflow::PermissionGrantor)
        .to receive(:grant_default_workflow_roles!)
        .with(permission_template: instance_of(Hyrax::PermissionTemplate))
        .exactly(3).times

      roles_service.grant_workflow_roles_for_all_admin_sets!
    end
  end

  describe '#seed_superadmin!' do
    it 'creates a user with the :superadmin role' do
      expect_any_instance_of(User).to receive(:add_default_group_membership!).once

      superadmin_user = roles_service.seed_superadmin!

      expect(superadmin_user).to be_persisted
      expect(superadmin_user).to be_valid
      expect(superadmin_user.has_role?(:superadmin)).to eq(true)
    end

    context 'when in the production environment' do
      before { allow(Rails.env).to receive(:production?).and_return(true) }
      after { allow(Rails.env).to receive(:production?).and_call_original } # un-stub

      it 'returns a warning' do
        expect(roles_service.seed_superadmin!)
          .to eq('Seed data should not be used in the production environment')
      end

      it 'does not create the superadmin' do
        expect { roles_service.seed_superadmin! }
          .not_to change(User, :count)
      end
    end
  end

  describe '#seed_qa_users!' do
    it 'creates a user for each default role' do
      expect { roles_service.seed_qa_users! }
        .to change(User, :count)
        .by(default_role_count)
    end

    context 'when in the production environment' do
      before { allow(Rails.env).to receive(:production?).and_return(true) }
      after { allow(Rails.env).to receive(:production?).and_call_original } # un-stub

      it 'returns a warning' do
        expect(roles_service.seed_qa_users!)
          .to eq('Seed data should not be used in the production environment')
      end

      it 'does not create the qa users' do
        expect { roles_service.seed_qa_users! }
          .not_to change(User, :count)
      end
    end
  end

  describe 'CleanReviewSubmissionsPageJob' do
    describe '#perform' do
      let(:entity1) { instance_double(Sipity::Entity, id: 1) }
      let(:entity2) { instance_double(Sipity::Entity, id: 2) }
      let(:entity3) { instance_double(Sipity::Entity, id: 3) }
      let(:entity4) { instance_double(Sipity::Entity, id: 4) }
      let(:entities) { [entity1, entity2, entity3, entity4] }

      before do
        allow(Sipity::Entity).to receive(:find_each).and_yield(entity1).and_yield(entity2).and_yield(entity3).and_yield(entity4)
        allow(entity1).to receive(:proxy_for).and_raise(Ldp::Gone)
        allow(entity1).to receive(:destroy)
        allow(entity2).to receive(:proxy_for).and_raise(Ldp::NotFound)
        allow(entity2).to receive(:destroy)
        allow(entity3).to receive(:proxy_for).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        allow(entity3).to receive(:destroy)
        allow(entity4).to receive(:proxy_for).and_return(true)
        allow(entity4).to receive(:destroy)
      end

      it 'destroys entities that raise any of the target errors' do
        roles_service.valid_jobs[:clean_review_submissions_page].new.perform
        expect(entity1).to have_received(:destroy)
        expect(entity2).to have_received(:destroy)
        expect(entity3).to have_received(:destroy)
      end

      it 'does not destroy entities that return successfully' do
        roles_service.valid_jobs[:clean_review_submissions_page].new.perform
        expect(entity4).not_to have_received(:destroy)
      end
    end
  end

  def access_count_for(role, permission_template, access)
    permission_template.access_grants.where(
      agent_type: Hyrax::PermissionTemplateAccess::GROUP,
      agent_id: role,
      access:
    ).count
  end
end
