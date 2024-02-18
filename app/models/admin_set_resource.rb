# frozen_string_literal: true

class AdminSetResource < Hyrax::AdministrativeSet
  include Hyrax::ArResource
  include Hyrax::Permissions::Readable
  Hyrax::ValkyrieLazyMigration.migrating(self, from: ::AdminSet)

  def permission_template
    return nil if id.blank?

    Hyrax::PermissionTemplate.find_by!(source_id: id)
  end
end
