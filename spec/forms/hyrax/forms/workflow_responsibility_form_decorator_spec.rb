# frozen_string_literal: true

RSpec.describe Hyrax::Forms::WorkflowResponsibilityForm, type: :decorator do
  describe ".new" do
    context "when user_id is present" do
      let(:user) { create(:user) }

      it "returns a WorkflowResponsibilityForm" do
        expect(described_class.new(user_id: user.id)).to be_a described_class
      end
    end

    context "when user_id is not present" do
      let(:group) { create(:group) }

      it "returns a WorkflowResponsibilityGroupForm" do
        expect(described_class.new(group_id: group.id)).to be_a Hyrax::Forms::WorkflowResponsibilityGroupForm
      end
    end
  end
end
