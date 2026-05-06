# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupAwareRoleChecker, clean: true do
  subject(:ability) { user.ability }

  let(:user) { FactoryBot.create(:user) }

  # Dynamically test all #<role_name>? methods so that, as more roles are added,
  # their role checker methods are automatically covered
  RolesService::DEFAULT_ROLES.each do |role_name|
    context "when the User has the :#{role_name} role" do
      before do
        user.add_role(role.name)
      end

      describe "##{role_name}?" do
        let(:role) { FactoryBot.create(:role, :"#{role_name}") }

        it { expect(ability.public_send("#{role_name}?")).to eq(true) }
      end
    end

    context "when the User has a Hyrax::Group membership that includes the :#{role_name} role" do
      before do
        hyrax_group.roles << role
        hyrax_group.add_members_by_id(user.id)
      end

      describe "##{role_name}?" do
        let(:role) { FactoryBot.create(:role, :"#{role_name}") }
        let(:hyrax_group) { FactoryBot.create(:group, name: "#{role_name.titleize}s") }

        it { expect(ability.public_send("#{role_name}?")).to eq(true) }
      end
    end

    context "when neither the User nor the User's Hyrax::Groups have the :#{role_name} role" do
      describe "##{role_name}?" do
        it { expect(ability.public_send("#{role_name}?")).to eq(false) }
      end
    end
  end

  describe 'query memoization' do
    after do
      allow(Site).to receive(:instance).and_call_original
    end

    let(:role_name) { RolesService::DEFAULT_ROLES.first }
    let(:site_instance_one) { FactoryBot.create(:site, application_name: "First site instance") }

    before do
      allow(Site).to receive(:instance).and_return(site_instance_one)
    end

    def count_queries(&block)
      count = 0
      counter = ->(*, **) { count += 1 }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end

    it 'does not issue additional queries on repeated calls to the same role check' do
      # warm up any lazy-loaded associations
      user.ability
      count_queries { user.ability.public_send("#{role_name}?") }
      queries_for_second_call = count_queries { user.ability.public_send("#{role_name}?") }
      expect(queries_for_second_call).to eq(0)
    end

    it 'does not issue additional queries when checking multiple roles' do
      abilities_warmup_count = count_queries { user.ability }

      queries_first_role = count_queries { user.ability.public_send("#{RolesService::DEFAULT_ROLES.first}?") }

      queries_second_role = count_queries { user.ability.public_send("#{RolesService::DEFAULT_ROLES.second}?") }

      # Second role check may query once to check that specific role,
      # but should not re-query hyrax_groups
      expect(queries_second_role).to be < abilities_warmup_count
      expect(queries_second_role).to be <= queries_first_role
    end

    # Regression for reviewer scenario: memo keyed only by site id would leak user A's
    # hyrax_groups to user B when the same checker object is reused with a different current_user.
    describe 'test_n_plus_one_exploration: hyrax_groups cache must not cross users on the same site' do
      subject(:checker) do
        Class.new do
          include GroupAwareRoleChecker
          attr_accessor :current_user
        end.new
      end

      let(:site_instance_one) { FactoryBot.create(:site, application_name: 'Shared site for memo test') }
      let(:user_one) { FactoryBot.create(:user) }
      let(:user_two) { FactoryBot.create(:user) }

      before do
        allow(Site).to receive(:instance).and_return(site_instance_one)
        FactoryBot.create(:group, name: 'memo-test-group-one', member_users: [user_one])
        FactoryBot.create(:group, name: 'memo-test-group-two', member_users: [user_two])
      end

      it 'returns the second user\'s groups after current_user changes (same site, same checker)' do
        checker.current_user = user_one
        groups_for_user_one = checker.send(:current_user_hyrax_groups, site_instance_one)

        checker.current_user = user_two
        groups_for_user_two = checker.send(:current_user_hyrax_groups, site_instance_one)

        expect(groups_for_user_one.map(&:id)).to match_array(user_one.reload.hyrax_groups.map(&:id))
        expect(groups_for_user_two.map(&:id)).to match_array(user_two.reload.hyrax_groups.map(&:id))
        expect(groups_for_user_two.map(&:id)).not_to match_array(groups_for_user_one.map(&:id))
      end
    end

    describe 'test_n_plus_one_exploration: group_role memo must not cross users on the same site' do
      subject(:checker) do
        Class.new do
          include GroupAwareRoleChecker
          attr_accessor :current_user
        end.new
      end

      let(:site_instance_one) { FactoryBot.create(:site, application_name: 'Shared site for group_role memo') }
      let(:user_without_admin) { FactoryBot.create(:user) }
      let(:user_with_admin) { FactoryBot.create(:admin) }

      before do
        allow(Site).to receive(:instance).and_return(site_instance_one)
      end

      it 'recomputes the role after current_user changes (same site, same checker)' do
        checker.current_user = user_without_admin
        expect(checker.public_send("#{RolesService::ADMIN_ROLE}?")).to be false

        checker.current_user = user_with_admin.reload
        expect(checker.public_send("#{RolesService::ADMIN_ROLE}?")).to be true
      end
    end
  end
end
