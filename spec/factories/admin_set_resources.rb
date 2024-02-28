# frozen_string_literal: true

# Extending https://github.com/samvera/hyrax/blob/main/spec/factories/administrative_sets.rb
FactoryBot.modify do
  factory :hyrax_admin_set do
    after(:create) do |admin_set, evaluator|
      if evaluator.with_permission_template&.is_a?(Hash) &&
         (evaluator.with_permission_template[:with_workflows] ||
          evaluator.with_permission_template['with_workflows'])

        permission_template = Hyrax::PermissionTemplate.find_by(source_id: admin_set.id.to_s)
        Hyrax::Workflow::WorkflowImporter.load_workflow_for(permission_template:)
        Sipity::Workflow.activate!(permission_template:, workflow_id: permission_template.available_workflows.pick(:id))
        Hyrax::Workflow::PermissionGrantor.grant_default_workflow_roles!(permission_template:)
        RolesService::CreateAdminSetAccessesJob.create_access_for(admin_set:)
      end
    end
  end
end

FactoryBot.define do
  # Create an AdminSetResource and it's corresponding permission template.
  #
  # ```ruby
  # FactoryBot.valkyrie_create(:hyku_admin_set, with_permission_template: true)
  # ```
  factory :hyku_admin_set, parent: :hyrax_admin_set, class: AdminSetResource do
  end
end
