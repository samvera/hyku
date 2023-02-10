# frozen_string_literal: true

RSpec.describe Hyrax::Forms::WorkflowResponsibilityGroupForm do
  let(:instance) { described_class.new }

  describe "#initialize" do
    subject { instance.model_instance }

    let(:group) { create(:group) }
    let(:instance) { described_class.new(group_id: group.id, workflow_role_id: 7) }

    it "creates an agent and sets the workflow_role_id" do
      expect(subject.agent).to be_kind_of Sipity::Agent
      expect(subject.workflow_role_id).to eq 7
    end
  end

  describe "#group_options" do
    subject { instance.group_options }

    it { is_expected.to eq Hyrax::Group.all }
  end

  describe "#workflow_role_options" do
    subject { instance.workflow_role_options }

    let(:wf_role1) { instance_double(Sipity::WorkflowRole, id: 1) }
    let(:wf_role2) { instance_double(Sipity::WorkflowRole, id: 2) }

    before do
      allow(Sipity::WorkflowRole).to receive(:all).and_return([wf_role1, wf_role2])
      allow(Hyrax::Admin::WorkflowRolePresenter).to receive(:new)
        .with(wf_role1)
        .and_return(instance_double(Hyrax::Admin::WorkflowRolePresenter,
                                    label: 'generic_work - foo'))
      allow(Hyrax::Admin::WorkflowRolePresenter).to receive(:new)
        .with(wf_role2)
        .and_return(instance_double(Hyrax::Admin::WorkflowRolePresenter,
                                    label: 'generic_work - bar'))
    end
    it { is_expected.to eq [['generic_work - bar', 2], ['generic_work - foo', 1]] }
  end
end
