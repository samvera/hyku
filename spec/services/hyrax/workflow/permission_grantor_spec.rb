# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Workflow::PermissionGrantor do
  subject(:permission_grantor) do
    described_class.new(
      permission_template:,
      creating_user:
    )
  end

  let(:permission_template) { build(:permission_template) }
  let(:creating_user) { create(:user) }
  let(:user) { create(:user) }
  let(:editor_user) { create(:user, roles: [:work_editor]) }
  let(:depositor_user) { create(:user, roles: [:work_depositor]) }
  let(:editors_group) { create(:editors_group) }
  let(:depositors_group) { create(:depositors_group) }

  describe '#initialize' do
    it 'requires a :permission_template argument' do
      expect { described_class.new }
        .to raise_error(ArgumentError, 'missing keyword: :permission_template')
    end

    it 'sets the :permission_template and :creating_user attributes' do
      expect(permission_grantor.permission_template).to eq(permission_template)
      expect(permission_grantor.creating_user).to eq(creating_user)
    end
  end

  describe '.grant_default_workflow_roles!' do
    it 'initializes an instance and calls #call on it' do
      expect_any_instance_of(described_class).to receive(:call)

      described_class.grant_default_workflow_roles!(permission_template:)
    end
  end

  describe '#call' do
    let(:permission_template) { create(:permission_template, with_admin_set: true, with_active_workflow: true) }
    let!(:admin_group) { Hyrax::Group.find_or_create_by!(name: ::Ability.admin_group_name) }

    it 'creates default sipity roles' do
      expect { permission_grantor.call }.to change(Sipity::Role, :count).by(3)
    end

    it 'grants MANAGING access to the admin group' do
      expect(sipity_role_names_for(admin_group.to_sipity_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(admin_group.to_sipity_agent.reload)).to include(Hyrax::RoleRegistry::MANAGING)
    end

    it 'grants MANAGING access to the creating user' do
      expect(sipity_role_names_for(creating_user.to_sipity_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(creating_user.to_sipity_agent.reload)).to include(Hyrax::RoleRegistry::MANAGING)
    end

    it 'grants MANAGING access to groups with the :admin role' do
      admin_group_1_agent = create(:group, roles: [:admin]).to_sipity_agent
      admin_group_2_agent = create(:group, roles: [:admin]).to_sipity_agent

      expect(sipity_role_names_for(admin_group_1_agent)).to be_empty
      expect(sipity_role_names_for(admin_group_2_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(admin_group_1_agent.reload)).to include(Hyrax::RoleRegistry::MANAGING)
      expect(sipity_role_names_for(admin_group_2_agent.reload)).to include(Hyrax::RoleRegistry::MANAGING)
    end

    it 'grants MANAGING access to users with the :admin role' do
      admin_1_agent = create(:admin).to_sipity_agent
      admin_2_agent = create(:admin).to_sipity_agent

      expect(sipity_role_names_for(admin_1_agent)).to be_empty
      expect(sipity_role_names_for(admin_2_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(admin_1_agent.reload)).to include(Hyrax::RoleRegistry::MANAGING)
      expect(sipity_role_names_for(admin_2_agent.reload)).to include(Hyrax::RoleRegistry::MANAGING)
    end

    it 'grants APPROVING access to groups with the :work_editor role' do
      expect(sipity_role_names_for(editors_group.to_sipity_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(editors_group.to_sipity_agent.reload)).to include(Hyrax::RoleRegistry::APPROVING)
    end

    it 'grants DEPOSITING access to groups with the :work_editor role' do
      expect(sipity_role_names_for(editors_group.to_sipity_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(editors_group.to_sipity_agent.reload)).to include(Hyrax::RoleRegistry::DEPOSITING)
    end

    it 'grants APPROVING access to users with the :work_editor role' do
      expect(sipity_role_names_for(editor_user.to_sipity_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(editor_user.to_sipity_agent.reload)).to include(Hyrax::RoleRegistry::APPROVING)
    end

    it 'grants DEPOSITING access to users with the :work_editor role' do
      expect(sipity_role_names_for(editor_user.to_sipity_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(editor_user.to_sipity_agent.reload)).to include(Hyrax::RoleRegistry::DEPOSITING)
    end

    it 'grants DEPOSITING access to groups with the :work_depositor role' do
      expect(sipity_role_names_for(depositors_group.to_sipity_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(depositors_group.to_sipity_agent.reload)).to include(Hyrax::RoleRegistry::DEPOSITING)
    end

    it 'grants DEPOSITING access to users with the :work_depositor role' do
      expect(sipity_role_names_for(depositor_user.to_sipity_agent)).to be_empty

      permission_grantor.call

      expect(sipity_role_names_for(depositor_user.to_sipity_agent.reload)).to include(Hyrax::RoleRegistry::DEPOSITING)
    end

    def sipity_role_names_for(agent)
      agent.workflow_responsibilities.map(&:workflow_role).map(&:role).map(&:name)
    end
  end
end
