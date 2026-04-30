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
  end
end
