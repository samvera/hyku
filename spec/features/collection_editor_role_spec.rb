# frozen_string_literal: true

require 'rails_helper'
RSpec.describe 'Collection editor role can be assigned to Groups and Users', type: :feature, clean: true do
  context 'a user assigned to a group' do
    let(:user) { FactoryBot.create(:user, display_name: "Jane Quest") }
    let(:user_ability) { ::Ability.new(user) }
    let(:group) { FactoryBot.create(:group, name: "Pirate Studies") }
    let(:role) { FactoryBot.create(:role, name: "Collection Editor") }

    it 'receives the privileges of the group' do
      expect(user_ability.collection_editor?).to eq false
      expect(group.members.include?(user)).to eq false
      expect(role.name).to eq "Collection Editor"
      expect(role.groups.include?(group)).to eq false
      expect(group.roles.include?(role)).to eq false
      # Assign Role to the Group
      group.roles << role
      expect(role.groups.include?(group)).to eq true
      expect(group.roles.include?(role)).to eq true
      # Add user to the group
      group.add_members_by_id(user.id)
      expect(group.members.include?(user)).to eq true
      expect(user.groups).to include("Pirate Studies")
      # Check to see if user has role that was assigned to group
      # TODO(bess) Next up: get the ability from the group membership
      # expect(user_ability.collection_editor?).to eq true
    end
  end
end
