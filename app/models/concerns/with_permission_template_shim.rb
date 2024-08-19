# frozen_string_literal: true

##
# Hyku has long assumed that certain models would respond to #permission_template.
#
# This shim provides that simple functionality.
module WithPermissionTemplateShim
  def permission_template
    return nil if id.blank?

    Hyrax::PermissionTemplate.find_by!(source_id: id)
  end
end
