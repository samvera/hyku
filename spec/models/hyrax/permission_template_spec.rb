# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::PermissionTemplate do
  describe 'spec factories' do
    it 'creates the permission template and can create workflows and a corresponding admin_set' do
      permission_template = FactoryBot.create(:permission_template, with_admin_set: true, with_workflows: true)
      expect(permission_template.active_workflow).to be_present
      expect(permission_template.source).to be_a Hyrax.config.admin_set_class
    end
  end
end
