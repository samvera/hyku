# frozen_string_literal: true

# OVERRIDE FILE from Hryax v2.9.0
require_dependency Hyrax::Engine.root.join('app', 'controllers', 'hyrax', 'admin', 'permission_template_accesses_controller').to_s

Hyrax::Admin::PermissionTemplateAccessesController.class_eval do
  # OVERRIDE: Only prevent delete if it is for the admin group's MANAGE access
  #
  # This is a controller validation rather than a model validation
  # because we don't want to prevent the ability to remove the whole
  # PermissionTemplate and all of its associated PermissionTemplateAccesses
  # @return [Boolean] true if it's valid
  def valid_delete?
    # OVERRIDE: add MANAGE access condition
    return true unless @permission_template_access.admin_group? && @permission_template_access.access == Hyrax::PermissionTemplateAccess::MANAGE

    @permission_template_access.errors[:base] << t('hyrax.admin.admin_sets.form.permission_destroy_errors.admin_group')
    false
  end
end
