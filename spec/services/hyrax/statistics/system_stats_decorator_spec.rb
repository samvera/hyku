# frozen_string_literal: true

RSpec.describe Hyrax::Statistics::SystemStats, type: :decorator do
  describe "#recent_users" do
    let!(:tenant_user) { create(:user) }
    # Users are shared across tenants; one from another tenant has no roles in this one
    let!(:other_tenant_user) { create(:user).tap { |user| user.roles = [] } }

    it "lists only users with a role in this tenant" do
      expect(described_class.new.recent_users.to_a).to eq [tenant_user]
    end

    it "counts them as a number, which the page prints" do
      expect(described_class.new.recent_users.count).to eq 1
    end

    it "filters by date the same way" do
      expect(described_class.new(5, 1.day.ago).recent_users.to_a).to eq [tenant_user]
    end
  end
end
