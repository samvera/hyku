# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupRole, type: :model, clean: true do
  let(:group) { FactoryBot.create(:group) }
  let(:role) { FactoryBot.create(:role) }

  it "associates a group with a role" do
    expect(GroupRole.count).to eq 0
    group.roles << role
    group.save
    expect(GroupRole.count).to eq 1
  end
end
