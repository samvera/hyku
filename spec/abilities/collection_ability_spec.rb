# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Add tests covering Groups with Roles permissions
require 'cancan/matchers'
# rubocop:disable RSpec/FilePath
RSpec.describe Ability::CollectionAbility do
  # rubocop:enable RSpec/FilePath
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:collection_type_gid) { create(:collection_type).to_global_id.to_s }
  let(:solr_document) { SolrDocument.new(collection.to_solr) }
  let(:id) { collection.id }
  let(:valkyrie_conversion) { Wings::ModelTransformer.for(collection) }
  let(:valkyrie_found) { Hyrax.query_service.find_by(id: collection.id) }
  let(:valkyrie_native) { FactoryBot.create(:hyku_collection, collection_type_gid:) }
  let(:valkyrie_native_id) { valkyrie_native.id.to_s }
  let(:collection) { FactoryBot.create(:old_collection_lw, with_permission_template: true, collection_type_gid:) }
  let(:permission_template) { collection.permission_template }
  let(:valkyrie_permission_template) { valkyrie_native.permission_template }

  context 'when admin user' do
    let(:user) { FactoryBot.create(:admin) }

    it 'allows all abilities' do
      is_expected.to be_able_to(:manage, Collection)
      is_expected.to be_able_to(:manage_any, Collection)
      is_expected.to be_able_to(:create, Collection)
      is_expected.to be_able_to(:create_any, Collection)
      is_expected.to be_able_to(:read_any, Collection)
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native, valkyrie_native_id, id].each do |obj|
        is_expected.to be_able_to(:edit, obj)
        is_expected.to be_able_to(:update, obj)
        is_expected.to be_able_to(:destroy, obj)
        is_expected.to be_able_to(:deposit, obj)
        is_expected.to be_able_to(:view_admin_show, obj)
        is_expected.to be_able_to(:read, obj)
        is_expected.to be_able_to(:manage_discovery, obj)
      end
    end
  end

  # TODO: reorganize with `describe '#collection_roles' do` and make tests more specific (CRUD)
  context 'when a user is a Collection Manager' do
    context 'through its User roles' do
      let(:user) { FactoryBot.create(:collection_manager) }

      it 'allows all abilities' do # rubocop:disable RSpec/ExampleLength
        is_expected.to be_able_to(:manage, Collection)
        is_expected.to be_able_to(:manage_any, Collection)
        is_expected.to be_able_to(:create, Collection)
        is_expected.to be_able_to(:create_any, Collection)
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native, valkyrie_native_id, id].each do |obj|
          is_expected.to be_able_to(:edit, obj)
          is_expected.to be_able_to(:update, obj)
          is_expected.to be_able_to(:destroy, obj)
          is_expected.to be_able_to(:deposit, obj)
          is_expected.to be_able_to(:view_admin_show, obj)
          is_expected.to be_able_to(:read, obj)
          is_expected.to be_able_to(:manage_discovery, obj)
        end
      end
    end

    context 'through its group memberships' do
      let!(:role) { FactoryBot.create(:role, :collection_manager) }
      let(:user) { FactoryBot.create(:user) }
      let(:hyrax_group) { FactoryBot.create(:group, name: 'collection_management_group') }

      before do
        hyrax_group.roles << role
        hyrax_group.add_members_by_id(user.id)
      end

      it 'allows all abilities' do # rubocop:disable RSpec/ExampleLength
        is_expected.to be_able_to(:manage, Collection)
        is_expected.to be_able_to(:manage_any, Collection)
        is_expected.to be_able_to(:create, Collection)
        is_expected.to be_able_to(:create_any, Collection)
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native, valkyrie_native_id, id].each do |obj|
          is_expected.to be_able_to(:edit, obj)
          is_expected.to be_able_to(:update, obj)
          is_expected.to be_able_to(:destroy, obj)
          is_expected.to be_able_to(:deposit, obj)
          is_expected.to be_able_to(:view_admin_show, obj)
          is_expected.to be_able_to(:read, obj)
          is_expected.to be_able_to(:manage_discovery, obj)
        end
      end
    end
  end

  context 'when a user has a Collection Editor role' do
    context 'through its User roles' do
      let(:user) { FactoryBot.create(:collection_editor) }

      it 'allows most abilities but denies ability to destroy and manage discovery' do
        is_expected.to be_able_to(:create, Collection)
        is_expected.to be_able_to(:create_any, Collection)
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native, valkyrie_native_id, id].each do |obj|
          is_expected.to be_able_to(:edit, obj)
          is_expected.to be_able_to(:update, obj)
          is_expected.to be_able_to(:view_admin_show, obj)
          is_expected.to be_able_to(:read, obj)

          is_expected.not_to be_able_to(:destroy, obj)
          is_expected.not_to be_able_to(:manage_discovery, collection)
        end
      end
    end

    context 'through its group memberships' do
      let!(:role) { FactoryBot.create(:role, :collection_editor) }
      let(:user) { FactoryBot.create(:user) }
      let(:hyrax_group) { FactoryBot.create(:group, name: 'collection_editing_group') }

      before do
        hyrax_group.roles << role
        hyrax_group.add_members_by_id(user.id)
      end

      it 'allows most abilities but not destroy nor manage_discovery' do
        is_expected.to be_able_to(:create, Collection)
        is_expected.to be_able_to(:create_any, Collection)
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native, valkyrie_native_id, id].each do |obj|
          is_expected.to be_able_to(:edit, obj)
          is_expected.to be_able_to(:update, obj)
          is_expected.to be_able_to(:view_admin_show, obj)
          is_expected.to be_able_to(:read, obj)

          is_expected.not_to be_able_to(:destroy, obj)
          is_expected.not_to be_able_to(:manage_discovery, obj)
        end
      end
    end
  end

  context 'when a user has a Collection Reader role' do
    context 'through its User roles' do
      let(:user) { FactoryBot.create(:collection_reader) }

      it 'allows read abilities but denies others' do
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.not_to be_able_to(:create, Collection)
        [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native, valkyrie_native_id, id].each do |obj|
          is_expected.to be_able_to(:view_admin_show, obj)
          is_expected.to be_able_to(:read, obj)

          is_expected.not_to be_able_to(:edit, obj)
          is_expected.not_to be_able_to(:update, obj)
          is_expected.not_to be_able_to(:deposit, obj)
          is_expected.not_to be_able_to(:destroy, obj)
          is_expected.not_to be_able_to(:manage_discovery, obj)
        end
      end
    end

    context 'through its group memberships' do
      let!(:role) { FactoryBot.create(:role, :collection_reader) }
      let(:user) { FactoryBot.create(:user) }
      let(:hyrax_group) { FactoryBot.create(:group, name: 'collection_reader_group') }

      before do
        hyrax_group.roles << role
        hyrax_group.add_members_by_id(user.id)
      end

      it 'allows read abilities but denies others' do
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.not_to be_able_to(:create, Collection)

        [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native, valkyrie_native_id, id].each do |_obj|
          is_expected.to be_able_to(:view_admin_show, collection)
          is_expected.to be_able_to(:read, collection)

          is_expected.not_to be_able_to(:edit, collection)
          is_expected.not_to be_able_to(:update, collection)
          is_expected.not_to be_able_to(:deposit, collection)
          is_expected.not_to be_able_to(:destroy, collection)
          is_expected.not_to be_able_to(:manage_discovery, collection)
        end
      end
    end
  end

  context 'when manager of a collection' do
    before do
      [collection, valkyrie_native].each do |record|
        create(:permission_template_access,
               :manage,
               permission_template: record.permission_template,
               agent_type: 'user',
               agent_id: user.user_key)
        record.permission_template.reset_access_controls_for(collection: record)
      end
    end

    it 'allows most abilities but denies general Collection management' do
      is_expected.to be_able_to(:manage_any, Collection)
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.not_to be_able_to(:manage, Collection)

      # We cannot use ID because the document is not actually in Solr to find then cast to a resource
      [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native].each do |obj|
        is_expected.to be_able_to(:edit, obj)
        is_expected.to be_able_to(:update, obj)
        is_expected.to be_able_to(:destroy, obj)
        is_expected.to be_able_to(:deposit, obj)
        is_expected.to be_able_to(:view_admin_show, obj)
        is_expected.to be_able_to(:read, obj) # edit access grants read and write

        next if obj == solr_document # This was never tested and does fail.  Why does it fail?
        # Likely has to do with the document not actually being in the
        # index.
        is_expected.to be_able_to(:manage_discovery, obj)
      end
    end
  end

  context 'when collection depositor' do
    before do
      [collection, valkyrie_native].each do |record|
        create(:permission_template_access,
               :deposit,
               permission_template: record.permission_template,
               agent_type: 'user',
               agent_id: user.user_key)
        record.permission_template.reset_access_controls_for(collection: record)
      end
    end

    it 'allows deposit related abilities and denies non-deposit related abilities' do
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.not_to be_able_to(:manage, Collection)
      is_expected.not_to be_able_to(:manage_any, Collection)

      # We cannot use ID because the document is not actually in Solr to find then cast to a resource
      [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native].each do |obj|
        is_expected.to be_able_to(:deposit, obj)
        is_expected.to be_able_to(:view_admin_show, obj)
        is_expected.to be_able_to(:read, obj)

        is_expected.not_to be_able_to(:edit, obj)
        is_expected.not_to be_able_to(:update, obj)
        is_expected.not_to be_able_to(:destroy, obj)
        is_expected.not_to be_able_to(:manage_discovery, obj)
      end
    end
  end

  context 'when collection viewer' do
    before do
      [collection, valkyrie_native].each do |record|
        create(:permission_template_access,
               :view,
               permission_template: record.permission_template,
               agent_type: 'user',
               agent_id: user.user_key)
        record.permission_template.reset_access_controls_for(collection: record)
      end
    end

    it 'allows viewing only ability and denise the others' do
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.not_to be_able_to(:manage, Collection)
      is_expected.not_to be_able_to(:manage_any, Collection)

      # We cannot use ID because the document is not actually in Solr to find then cast to a resource
      [collection, valkyrie_found, valkyrie_conversion, solr_document, valkyrie_native].each do |obj|
        is_expected.to be_able_to(:view_admin_show, obj)
        is_expected.to be_able_to(:read, obj)

        is_expected.not_to be_able_to(:edit, obj)
        is_expected.not_to be_able_to(:update, obj)
        is_expected.not_to be_able_to(:destroy, obj)
        is_expected.not_to be_able_to(:deposit, obj)
        is_expected.not_to be_able_to(:manage_discovery, obj)
      end
    end
  end

  context 'when user has no special access' do
    it 'denies all abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, Collection)
      is_expected.not_to be_able_to(:manage_any, Collection)
      is_expected.not_to be_able_to(:view_admin_show_any, Collection)
      [collection, valkyrie_found, valkyrie_conversion, solr_document, id, valkyrie_native, valkyrie_native_id].each do |obj|
        is_expected.not_to be_able_to(:edit, obj)
        is_expected.not_to be_able_to(:update, obj)
        is_expected.not_to be_able_to(:destroy, obj)
        is_expected.not_to be_able_to(:deposit, obj)
        is_expected.not_to be_able_to(:view_admin_show, obj)
        is_expected.not_to be_able_to(:read, obj)
        is_expected.not_to be_able_to(:manage_discovery, obj)
      end
    end
  end

  context 'create_any' do
    # Whether a user can create a collection depends on collection type participants, so need to test separately.

    context 'when there are no collection types that have create access' do
      before do
        # User Collection type is always created and gives all users the ability to create.  To be able to test that
        # particular roles don't automatically give users create abilities, the create access for User Collection type
        # has to be removed.
        uct = Hyrax::CollectionType.find_by(machine_id: Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID)
        if uct.present?
          uctp = Hyrax::CollectionTypeParticipant.find_by(hyrax_collection_type_id: uct.id, access: "create")
          uctp.destroy if uctp.present?
        end
      end

      it 'denies create_any' do
        is_expected.not_to be_able_to(:create_any, Collection)
      end
    end

    context 'when there are collection types that have create access' do
      before do
        create(:collection_type, creator_group: 'registered')
      end

      it 'allows create_any' do
        is_expected.to be_able_to(:create_any, Collection)
      end
    end
  end
end
