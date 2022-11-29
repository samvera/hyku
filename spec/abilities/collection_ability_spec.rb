# OVERRIDE FILE from Hyrax 3.4.1
require 'cancan/matchers'
# rubocop:disable RSpec/FilePath
RSpec.describe Ability::CollectionAbility do
  # rubocop:enable RSpec/FilePath
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:collection_type_gid) { create(:collection_type).gid }
  let(:solr_document) { SolrDocument.new(collection.to_solr) }
  let(:id) { collection.id }

  context 'when admin user' do
    let(:user) { FactoryBot.create(:admin) }
    let(:collection) { build(:collection_lw, id: 'col_au', with_permission_template: true, collection_type_gid: collection_type_gid) }

    it 'allows all abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.to be_able_to(:manage, Collection)
      is_expected.to be_able_to(:manage_any, Collection)
      is_expected.to be_able_to(:create, Collection)
      is_expected.to be_able_to(:create_any, Collection)
      is_expected.to be_able_to(:read_any, Collection)
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.to be_able_to(:edit, collection)
      is_expected.to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:update, collection)
      is_expected.to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:destroy, collection)
      is_expected.to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:deposit, collection)
      is_expected.to be_able_to(:deposit, solr_document)
      is_expected.to be_able_to(:view_admin_show, collection)
      is_expected.to be_able_to(:view_admin_show, solr_document)
      is_expected.to be_able_to(:read, collection)
      is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:manage_discovery, collection)
    end
  end

  # TODO: reorganize with `describe '#collection_roles' do` and make tests more specific (CRUD)
  context 'when a user is a Collection Manager' do
    let(:collection) { create(:collection_lw, with_permission_template: true, collection_type_gid: collection_type_gid) }

    context 'through its User roles' do
      let(:user) { FactoryBot.create(:collection_manager) }

      it 'allows all abilities' do # rubocop:disable RSpec/ExampleLength
        is_expected.to be_able_to(:manage, Collection)
        is_expected.to be_able_to(:manage_any, Collection)
        is_expected.to be_able_to(:create, Collection)
        is_expected.to be_able_to(:create_any, Collection)
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:edit, collection)
        is_expected.to be_able_to(:edit, solr_document)
        is_expected.to be_able_to(:edit, id)
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:update, solr_document)
        is_expected.to be_able_to(:update, id)
        is_expected.to be_able_to(:destroy, collection)
        is_expected.to be_able_to(:destroy, solr_document)
        is_expected.to be_able_to(:destroy, id)
        is_expected.to be_able_to(:deposit, collection)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:deposit, id)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:view_admin_show, id)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document)
        is_expected.to be_able_to(:read, id)
        is_expected.to be_able_to(:manage_discovery, collection)
        is_expected.to be_able_to(:manage_discovery, solr_document)
        is_expected.to be_able_to(:manage_discovery, id)
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
        is_expected.to be_able_to(:edit, collection)
        is_expected.to be_able_to(:edit, solr_document)
        is_expected.to be_able_to(:edit, id)
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:update, solr_document)
        is_expected.to be_able_to(:update, id)
        is_expected.to be_able_to(:destroy, collection)
        is_expected.to be_able_to(:destroy, solr_document)
        is_expected.to be_able_to(:destroy, id)
        is_expected.to be_able_to(:deposit, collection)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:deposit, id)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:view_admin_show, id)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document)
        is_expected.to be_able_to(:read, id)
        is_expected.to be_able_to(:manage_discovery, collection)
        is_expected.to be_able_to(:manage_discovery, solr_document)
        is_expected.to be_able_to(:manage_discovery, id)
      end
    end
  end

  context 'when a user has a Collection Editor role' do
    let(:collection) { create(:collection_lw, with_permission_template: true, collection_type_gid: collection_type_gid) }

    context 'through its User roles' do
      let(:user) { FactoryBot.create(:collection_editor) }

      it 'allows most abilities' do # rubocop:disable RSpec/ExampleLength
        is_expected.to be_able_to(:create, Collection)
        is_expected.to be_able_to(:create_any, Collection)
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:edit, collection)
        is_expected.to be_able_to(:edit, solr_document)
        is_expected.to be_able_to(:edit, id)
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:update, solr_document)
        is_expected.to be_able_to(:update, id)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:view_admin_show, id)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document)
        is_expected.to be_able_to(:read, id)
      end

      it 'denies destroy ability' do
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, id)
      end

      it 'denies manage_discovery ability' do
        is_expected.not_to be_able_to(:manage_discovery, collection)
        is_expected.not_to be_able_to(:manage_discovery, solr_document)
        is_expected.not_to be_able_to(:manage_discovery, id)
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

      it 'allows most abilities' do # rubocop:disable RSpec/ExampleLength
        is_expected.to be_able_to(:create, Collection)
        is_expected.to be_able_to(:create_any, Collection)
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:edit, collection)
        is_expected.to be_able_to(:edit, solr_document)
        is_expected.to be_able_to(:edit, id)
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:update, solr_document)
        is_expected.to be_able_to(:update, id)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:view_admin_show, id)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document)
        is_expected.to be_able_to(:read, id)
      end

      it 'denies destroy ability' do
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, id)
      end

      it 'denies manage_discovery ability' do
        is_expected.not_to be_able_to(:manage_discovery, collection)
        is_expected.not_to be_able_to(:manage_discovery, solr_document)
        is_expected.not_to be_able_to(:manage_discovery, id)
      end
    end
  end

  context 'when a user has a Collection Reader role' do
    let(:collection) { create(:collection_lw, with_permission_template: true, collection_type_gid: collection_type_gid) }

    context 'through its User roles' do
      let(:user) { FactoryBot.create(:collection_reader) }

      it 'allows read abilities' do # rubocop:disable RSpec/ExampleLength
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:view_admin_show, id)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document)
        is_expected.to be_able_to(:read, id)
      end

      it 'denies most abilities' do
        is_expected.not_to be_able_to(:create, Collection)
        is_expected.not_to be_able_to(:edit, collection)
        is_expected.not_to be_able_to(:edit, solr_document)
        is_expected.not_to be_able_to(:edit, id)
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:update, solr_document)
        is_expected.not_to be_able_to(:update, id)
        is_expected.not_to be_able_to(:deposit, collection)
        is_expected.not_to be_able_to(:deposit, solr_document)
        is_expected.not_to be_able_to(:deposit, id)
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, id)
        is_expected.not_to be_able_to(:manage_discovery, collection)
        is_expected.not_to be_able_to(:manage_discovery, solr_document)
        is_expected.not_to be_able_to(:manage_discovery, id)
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

      it 'allows read abilities' do # rubocop:disable RSpec/ExampleLength
        is_expected.to be_able_to(:read_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:view_admin_show, id)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document)
        is_expected.to be_able_to(:read, id)
      end

      it 'denies most abilities' do
        is_expected.not_to be_able_to(:create, Collection)
        is_expected.not_to be_able_to(:edit, collection)
        is_expected.not_to be_able_to(:edit, solr_document)
        is_expected.not_to be_able_to(:edit, id)
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:update, solr_document)
        is_expected.not_to be_able_to(:update, id)
        is_expected.not_to be_able_to(:deposit, collection)
        is_expected.not_to be_able_to(:deposit, solr_document)
        is_expected.not_to be_able_to(:deposit, id)
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, id)
        is_expected.not_to be_able_to(:manage_discovery, collection)
        is_expected.not_to be_able_to(:manage_discovery, solr_document)
        is_expected.not_to be_able_to(:manage_discovery, id)
      end
    end
  end

  context 'when manager of a collection' do
    let(:collection) { create(:collection_lw, with_permission_template: true, collection_type_gid: collection_type_gid) }

    before do
      create(:permission_template_access,
             :manage,
             permission_template: collection.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.reset_access_controls!
    end

    it 'allows most abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.to be_able_to(:manage_any, Collection)
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.to be_able_to(:edit, collection)
      is_expected.to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:edit, id)
      is_expected.to be_able_to(:update, collection)
      is_expected.to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:update, id)
      is_expected.to be_able_to(:destroy, collection)
      is_expected.to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:destroy, id)
      is_expected.to be_able_to(:deposit, collection)
      is_expected.to be_able_to(:deposit, solr_document)
      is_expected.to be_able_to(:view_admin_show, collection)
      is_expected.to be_able_to(:view_admin_show, solr_document)
      is_expected.to be_able_to(:read, collection) # edit access grants read and write
      is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:read, id)
      is_expected.to be_able_to(:manage_discovery, collection)
    end

    it 'denies manage ability' do
      is_expected.not_to be_able_to(:manage, Collection)
    end
  end

  context 'when collection depositor' do
    let(:collection) { create(:collection_lw, with_permission_template: true, collection_type_gid: collection_type_gid) }

    before do
      create(:permission_template_access,
             :deposit,
             permission_template: collection.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.reset_access_controls!
    end

    it 'allows deposit related abilities' do
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.to be_able_to(:deposit, collection)
      is_expected.to be_able_to(:deposit, solr_document)
      is_expected.to be_able_to(:view_admin_show, collection)
      is_expected.to be_able_to(:view_admin_show, solr_document)
      is_expected.to be_able_to(:read, collection)
      is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:read, id)
    end

    it 'denies non-deposit related abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, Collection)
      is_expected.not_to be_able_to(:manage_any, Collection)
      is_expected.not_to be_able_to(:edit, collection)
      is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:edit, id)
      is_expected.not_to be_able_to(:update, collection)
      is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:update, id)
      is_expected.not_to be_able_to(:destroy, collection)
      is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:destroy, id)
      is_expected.not_to be_able_to(:manage_discovery, collection)
      is_expected.not_to be_able_to(:manage_discovery, solr_document)
      is_expected.not_to be_able_to(:manage_discovery, id)
    end
  end

  context 'when collection viewer' do
    let(:collection) { create(:collection_lw, with_permission_template: true, collection_type_gid: collection_type_gid) }

    before do
      create(:permission_template_access,
             :view,
             permission_template: collection.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.reset_access_controls!
    end

    it 'allows viewing only ability' do
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.to be_able_to(:view_admin_show, collection)
      is_expected.to be_able_to(:view_admin_show, solr_document)
      is_expected.to be_able_to(:read, collection)
      is_expected.to be_able_to(:read, solr_document)
      is_expected.to be_able_to(:read, id)
    end

    it 'denies most abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, Collection)
      is_expected.not_to be_able_to(:manage_any, Collection)
      is_expected.not_to be_able_to(:edit, collection)
      is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:edit, id)
      is_expected.not_to be_able_to(:update, collection)
      is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:update, id)
      is_expected.not_to be_able_to(:destroy, collection)
      is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:destroy, id)
      is_expected.not_to be_able_to(:deposit, collection)
      is_expected.not_to be_able_to(:deposit, solr_document)
      is_expected.not_to be_able_to(:deposit, id)
      is_expected.not_to be_able_to(:manage_discovery, collection)
      is_expected.not_to be_able_to(:manage_discovery, solr_document)
      is_expected.not_to be_able_to(:manage_discovery, id)
    end
  end

  context 'when user has no special access' do
    let(:collection) { create(:collection_lw, with_permission_template: true, collection_type_gid: collection_type_gid) }

    it 'denies all abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, Collection)
      is_expected.not_to be_able_to(:manage_any, Collection)
      is_expected.not_to be_able_to(:view_admin_show_any, Collection)
      is_expected.not_to be_able_to(:edit, collection)
      is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:edit, id)
      is_expected.not_to be_able_to(:update, collection)
      is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:update, id)
      is_expected.not_to be_able_to(:destroy, collection)
      is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:destroy, id)
      is_expected.not_to be_able_to(:deposit, collection)
      is_expected.not_to be_able_to(:deposit, solr_document)
      is_expected.not_to be_able_to(:deposit, id)
      is_expected.not_to be_able_to(:view_admin_show, collection)
      is_expected.not_to be_able_to(:view_admin_show, solr_document)
      is_expected.not_to be_able_to(:view_admin_show, id)
      is_expected.not_to be_able_to(:read, collection)
      is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:read, id)
      is_expected.not_to be_able_to(:manage_discovery, collection)
      is_expected.not_to be_able_to(:manage_discovery, solr_document)
      is_expected.not_to be_able_to(:manage_discovery, id)
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
