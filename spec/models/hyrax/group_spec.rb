# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/ModuleLength
module Hyrax
  RSpec.describe Group, type: :model, clean: true do
    describe '.new' do
      context 'when provided a string' do
        it 'instantiates with the string as the name' do
          expect(described_class.new("Boaty McBoatFace").name).to eq('Boaty McBoatFace')
        end
      end
      context 'when provided a hash' do
        it 'instantiates' do
          expect(described_class.new(name: "Boaty McBoatFace").name).to eq('Boaty McBoatFace')
        end
      end
    end
    describe 'group with no members' do
      subject { described_class.new(name:, description:) }

      let(:name) { 'Empty Group' }
      let(:description) { 'Add members plz' }
      let(:empty_group_attributes) do
        {
          name:,
          description:,
          number_of_users: 0
        }
      end

      it { is_expected.to have_attributes(empty_group_attributes) }
      it { is_expected.to respond_to(:created_at) }
    end

    context '.search' do
      context 'with a query' do
        before do
          FactoryBot.create(:group, humanized_name: 'IMPORTANT-GROUP-NAME')
          FactoryBot.create(:group, description: 'IMPORTANT-GROUP-DESCRIPTION')
          FactoryBot.create(:group, roles: ['important_people', 'test'])
        end

        it 'returns groups that match a query on a humanized name' do
          expect(described_class.search('IMPORTANT-GROUP-NAME').count).to eq(1)
        end

        it 'returns groups that match a query on a description' do
          expect(described_class.search('IMPORTANT-GROUP-DESCRIPTION').count).to eq(1)
        end

        it 'returns groups with a partial match' do
          expect(described_class.search('IMPORTANT-GROUP').count).to eq(2)
        end

        it 'returns an empty set when there is no match' do
          expect(described_class.search('NULL').count).to eq(0)
        end

        it 'returns groups that match a query on a role name' do
          expect(described_class.search('test').count).to eq(1)
          expect(described_class.search('important').count).to eq(3)
        end

        it 'is case-insensitive' do
          expect(described_class.search('important-group-name').count).to eq(1)
          expect(described_class.search('iMpOrTaNt').count).to eq(3)
          expect(described_class.search('TEST').count).to eq(1)
        end

        it 'searches humanized versions of role names' do
          expect(described_class.search('Important People').count).to eq(1)
        end
      end

      context 'without a query' do
        before do
          FactoryBot.create(:group, humanized_name: 'Users')
          FactoryBot.create(:group, humanized_name: 'Depositors', roles: ['work_depositor'])
          FactoryBot.create(:group, humanized_name: 'Readers', roles: ['user_reader'])
          FactoryBot.create(:group, humanized_name: 'Managers', roles: ['admin'])
          FactoryBot.create(:group, humanized_name: 'Editors', roles: ['collection_editor'])
        end

        it 'returns all groups' do
          expect(described_class.search(nil).count).to eq(5)
        end

        # See Role#set_sort_value
        it "orders groups by their roles' sort_value" do
          result = described_class.search(nil)

          expect(result[0].humanized_name).to eq('Managers')
          expect(result[1].humanized_name).to eq('Editors')
          expect(result[2].humanized_name).to eq('Depositors')
          expect(result[3].humanized_name).to eq('Readers')
          expect(result[4].humanized_name).to eq('Users')
        end
      end
    end

    context '#search_members' do
      subject { FactoryBot.create(:group) }

      let(:known_user_name) { FactoryBot.create(:user, display_name: 'Tom Cramer') }
      let(:known_user_email) { FactoryBot.create(:user, email: 'tom@project-hydra.com') }

      before { subject.add_members_by_id([known_user_name.id, known_user_email.id]) }

      it 'returns members based on name' do
        expect(subject.search_members(known_user_name.name).count).to eq(1)
      end

      it 'returns members based on email' do
        expect(subject.search_members(known_user_email.email).count).to eq(1)
      end

      it 'returns members based on partial matches' do
        expect(subject.search_members('Tom').count).to eq(1)
      end

      it 'returns an empty set when there is no match' do
        expect(subject.search_members('Jerry').count).to eq(0)
      end
    end

    context '#destroy' do
      context 'when destroying a non-default group' do
        let!(:group) { FactoryBot.create(:group) }
        let(:user_1) { FactoryBot.create(:user) }
        let(:user_2) { FactoryBot.create(:user) }

        it 'destroys successfully' do
          expect { group.destroy }.to change(Hyrax::Group, :count).by(-1)
        end

        it 'removes the membership role for all members of the group' do
          group.add_members_by_id([user_1.id, user_2.id])
          expect(user_1.hyrax_groups).to include(group)
          expect(user_2.hyrax_groups).to include(group)
          expect(
            Role.where(
              resource_id: group.id,
              resource_type: 'Hyrax::Group',
              name: 'member'
            ).count
          ).to eq(1) # group's membership Role

          expect { group.destroy }.to change(Role, :count).by(-1)

          expect(user_1.hyrax_groups).not_to include(group)
          expect(user_2.hyrax_groups).not_to include(group)
          expect(
            Role.where(
              resource_id: group.id,
              resource_type: 'Hyrax::Group',
              name: 'member'
            ).count
          ).to eq(0) # group's membership Role
        end
      end

      context 'when attempting to destroy a default group' do
        let(:admin_group) { FactoryBot.create(:admin_group) }
        let(:registered_group) { FactoryBot.create(:registered_group) }
        let(:editors_group) { FactoryBot.create(:editors_group) }
        let(:depositors_group) { FactoryBot.create(:depositors_group) }

        it 'does not succeed' do
          expect { admin_group.destroy }.not_to change(Hyrax::Group, :count)
          expect { registered_group.destroy }.not_to change(Hyrax::Group, :count)
          expect { editors_group.destroy }.not_to change(Hyrax::Group, :count)
          expect { depositors_group.destroy }.not_to change(Hyrax::Group, :count)
        end
      end
    end

    describe '#add_members_by_id' do
      subject { FactoryBot.create(:group) }

      let(:user) { FactoryBot.create(:user) }

      before { subject.add_members_by_id(user.id) }

      it 'adds one user when passed a single user id' do
        expect(subject.members).to include(user)
      end

      # This is tested in the setup of #search_members and #remove_members_by_id
      it 'adds multiple users when passed a collection of user ids' do
      end
    end

    describe '#remove_members_by_id' do
      subject { FactoryBot.create(:group) }

      context 'single user id' do
        let(:user) { FactoryBot.create(:user) }

        before { subject.add_members_by_id(user.id) }

        it 'removes one user' do
          expect(subject.members).to include(user)
          subject.remove_members_by_id(user.id)
          expect(subject.members).not_to include(user)
        end
      end

      context 'collection of user ids' do
        let(:user_list) { FactoryBot.create_list(:user, 3) }
        let(:user_ids) { user_list.collect(&:id) }

        before { subject.add_members_by_id(user_ids) }

        it 'removes multiple users' do
          expect(subject.members.collect(&:id)).to eq(user_ids)
          subject.remove_members_by_id(user_ids)
          expect(subject.members.count).to eq(0)
        end
      end
    end

    context '#number_of_users' do
      subject { FactoryBot.create(:group) }

      let(:user) { FactoryBot.create(:user) }

      it 'starts out with 0 users' do
        expect(subject.number_of_users).to eq(0)
      end

      it 'increments when users are added' do
        subject.add_members_by_id(user.id)
        expect(subject.number_of_users).to eq(1)
      end
    end

    ##
    # A Role can be assigned to a group, and this will grant all Users who are members of that Group certain abilities
    context 'roles' do
      context '#roles' do
        let(:group1) { described_class.create(name: "Pirate Studies") }
        let(:group2) { described_class.create(name: "Arcane Arts") }
        let(:edit_collection_role) { FactoryBot.create(:role, name: "Edit Collection") }

        it "can add a role" do
          group1.roles << edit_collection_role
          group2.roles << edit_collection_role
          expect(group1.roles).to be_present
          expect(group2.roles).to be_present
          expect(group1.roles).to include(edit_collection_role)
          expect(group2.roles).to include(edit_collection_role)
        end
      end

      describe '#site_role?' do
        subject(:group) { FactoryBot.build(:group) }

        before do
          group.roles << role
        end

        context 'when group has a non-site role that matches' do
          let(:role) { FactoryBot.build(:role, name: 'non-site role', resource_type: 'non-site type') }

          it 'returns false' do
            expect(group.site_role?('non-site role')).to eq(false)
          end
        end

        context 'when group has a site role that matches' do
          let(:role) { FactoryBot.build(:role, name: 'my_role', resource_type: 'Site') }

          it 'returns true' do
            expect(group.site_role?('my_role')).to eq(true)
          end

          it 'handles being passed a symbol' do
            expect(group.site_role?(:my_role)).to eq(true)
          end
        end

        context 'when group has a site role that does not matches' do
          let(:role) { FactoryBot.build(:role, name: 'my_role', resource_type: 'Site') }

          it 'returns false' do
            expect(group.site_role?('your_role')).to eq(false)
          end
        end
      end
    end

    context '#default_group?' do
      let(:admin_group) { FactoryBot.create(:admin_group) }
      let(:registered_group) { FactoryBot.create(:registered_group) }
      let(:editors_group) { FactoryBot.create(:editors_group) }
      let(:depositors_group) { FactoryBot.create(:depositors_group) }
      let(:non_default_group) { FactoryBot.create(:group) }

      it 'returns true if the group is a Default Group' do
        expect(admin_group.default_group?).to eq true
        expect(registered_group.default_group?).to eq true
        expect(editors_group.default_group?).to eq true
        expect(depositors_group.default_group?).to eq true
        expect(non_default_group.default_group?).to eq false
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
