module Hyku
  RSpec.describe Group do
    describe 'group with no members' do
      subject { described_class.new(name: name, description: description) }

      let(:name) { 'Empty Group' }
      let(:description) { 'Add members plz' }
      let(:empty_group_attributes) do
        {
          name: name,
          description: description,
          number_of_users: 0
        }
      end

      it { is_expected.to have_attributes(empty_group_attributes) }
      it { is_expected.to respond_to(:created_at) }
    end

    context '.search' do
      before(:context) do
        FactoryBot.create(:group, name: 'IMPORTANT-GROUP-NAME')
        FactoryBot.create(:group, description: 'IMPORTANT-GROUP-DESCRIPTION')
      end

      after(:context) do
        described_class.all.each(&:destroy)
      end

      it 'returns groups that match a query on a name' do
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
  end
end
