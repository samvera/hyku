# TODO: These changes should move into Hyrax
Hyrax::Admin::WorkflowRolesController.class_eval do
  layout 'admin'

  before_action only: [:index] do
    add_breadcrumb t(:'hyrax.controls.home'), root_path
    add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
    add_breadcrumb t(:'hyrax.admin.workflow_roles.header'), hyrax.admin_workflow_roles_path
    # TODO: Find a better way to make sure workflows are loaded
    Hyrax::Workflow::WorkflowImporter.load_workflows
  end
end
