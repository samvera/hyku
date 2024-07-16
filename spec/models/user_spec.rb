# frozen_string_literal: true

RSpec.describe User, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  before do
    travel_to Time.zone.local(2024, 6, 15, 12, 0, 0)
  end

  after do
    travel_back
  end

  subject { FactoryBot.create(:user) }

  it 'validates email and password' do
    is_expected.to validate_presence_of(:email)
    is_expected.to validate_presence_of(:password)
  end

  context '#stistics_for' do
    let(:account) { FactoryBot.create(:account) }

    before do
      allow(Apartment::Tenant).to receive(:switch).and_yield
    end

    describe 'no statistics' do
      it 'returns nil' do
        expect(subject.statistics_for).to be nil
      end
    end

    describe 'with user statistics' do
      let!(:stat_1_prior_month) { UserStat.create!(user_id: subject.id, date: 1.month.ago, file_views: 3, file_downloads: 2, work_views: 5) }
      let!(:stat_2_prior_month) { UserStat.create!(user_id: subject.id, date: 1.month.ago, file_views: 2, file_downloads: 1, work_views: 7) }
      let!(:stat_2_months_ago) { UserStat.create!(user_id: subject.id, date: 2.months.ago, file_views: 1, file_downloads: 1, work_views: 1) }
      let!(:stat_yesterday) { UserStat.create!(user_id: subject.id, date: 1.day.ago, file_views: 1, file_downloads: 2, work_views: 3) }
      let!(:someone_elses_user_id) { subject.id + 1 }
      let!(:not_my_stat) { UserStat.create!(user_id: someone_elses_user_id, date: 1.month.ago, file_views: 10, file_downloads: 11) }
      let(:user_stats) { { new_file_downloads: 3, new_work_views: 12, total_file_downloads: 6, total_file_views: 7, total_work_views: 16 } }
      let(:yesterday_stats) { { new_file_downloads: 2, new_work_views: 3, total_file_downloads: 6, total_file_views: 7, total_work_views: 16 } }

      it 'returns a summary hash of prior months stats' do
        # requires time traveling because the :stat_yesterday will be included which is the expected behavior
        # but just throws the specs off on the first of the month
        expect(subject.statistics_for).to eq(user_stats)
      end

      it 'summarizes stats for specified date range' do
        expect(subject.statistics_for(start_date: Time.zone.now - 2.days, end_date: Time.zone.now)).to eq(yesterday_stats)
      end

      it 'returns nil if no statistics in specified date range' do
        expect(subject.statistics_for(start_date: Time.zone.now - 4.months, end_date: Time.zone.now - 5.months)).to be nil
      end

      it 'returns nil if start and end dates the same' do
        expect(subject.statistics_for(start_date: Time.zone.now - 5.months, end_date: Time.zone.now - 5.months)).to be nil
      end
    end
  end

  context 'the first created user in global tenant' do
    before do
      allow(Account).to receive(:global_tenant?).and_return true
    end

    it 'does not get the admin role' do
      expect(subject.persisted?).to eq true
      expect(subject).not_to have_role :admin
      expect(subject).not_to have_role :admin, Site.instance
    end
  end

  context 'the first created user on a tenant' do
    it 'is not given the admin role' do
      expect(subject).not_to have_role :admin
      expect(subject).not_to have_role :admin, Site.instance
    end
  end

  context 'a subsequent user' do
    let!(:first_user) { FactoryBot.create(:user) }
    let!(:next_user) { FactoryBot.create(:user) }

    it 'is not given the admin role' do
      expect(next_user).not_to have_role :admin
      expect(next_user).not_to have_role :admin, Site.instance
    end
  end

  describe '#site_roles' do
    subject { FactoryBot.create(:admin) }

    it 'fetches the global roles assigned to the user' do
      expect(subject.site_roles.pluck(:name)).to match_array ['admin']
    end
  end

  describe '#site_roles=' do
    it 'assigns global roles to the user' do
      expect(subject.site_roles.pluck(:name)).to be_empty

      subject.update(site_roles: ['admin'])

      expect(subject.site_roles.pluck(:name)).to match_array ['admin']
    end

    it 'removes roles' do
      subject.update(site_roles: ['admin'])
      subject.update(site_roles: [])
      expect(subject.site_roles.pluck(:name)).to be_empty
    end
  end

  describe '#hyrax_groups' do
    it 'returns an array of Hyrax::Groups' do
      expect(subject.hyrax_groups).to be_an_instance_of(Array)
      expect(subject.hyrax_groups.first).to be_an_instance_of(Hyrax::Group)
    end
  end

  describe '#groups' do
    before do
      FactoryBot.create(:group, name: 'group1', member_users: [subject])
    end

    it 'returns the names of the Hyrax::Groups the user is a member of' do
      expect(subject.groups).to include('group1')
    end
  end

  describe '#hyrax_group_names' do
    before do
      FactoryBot.create(:group, name: 'group1', member_users: [subject])
    end

    it 'returns the names of the Hyrax::Groups the user is a member of' do
      expect(subject.hyrax_group_names).to include('group1')
    end
  end

  describe '#add_default_group_membership!' do
    context 'when the user is a new user' do
      subject { FactoryBot.build(:user) }

      it 'is called after a user is created' do
        expect(subject).to receive(:add_default_group_membership!) # rubocop:disable RSpec/SubjectStub

        subject.save!
      end
    end

    # #add_default_group_membership! does nothing for guest users;
    # 'public' is the default group for all users (including guests).
    # See Ability#default_user_groups in blacklight-access_controls-0.6.2
    context 'when the user is a guest user' do
      subject { FactoryBot.build(:guest_user) }

      it 'does not get any Hyrax::Group memberships' do
        expect(subject.hyrax_group_names).to eq([])

        subject.save!

        expect(subject.hyrax_group_names).to eq([])
      end
    end

    context 'when the user is a registered user' do
      subject { FactoryBot.build(:user) }

      it 'adds the user as a member of the registered Hyrax::Group' do
        expect(subject.hyrax_group_names).to eq([])

        subject.save!

        expect(subject.hyrax_group_names).to contain_exactly('registered')
      end
    end
  end

  describe '#mark_all_undelivered_messages_as_delivered!' do
    let(:receipt) { create(:mailboxer_receipt, receiver: subject) }

    before do
      # ensure we have a undelivered receipt
      receipt.update(is_delivered: false)
    end

    context 'when batch_email_frequency is set to never' do
      it 'marks all undelivered messages as delivered' do
        subject.update(batch_email_frequency: 'never')
        expect(receipt.reload.is_delivered).to be true
      end
    end

    context 'when batch_email_frequency is not set to never' do
      it 'does not mark all undelivered messages as delivered' do
        subject.update(batch_email_frequency: 'daily')
        expect(receipt.reload.is_delivered).to be false
      end
    end
  end
end
