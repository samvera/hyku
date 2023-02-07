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
end
