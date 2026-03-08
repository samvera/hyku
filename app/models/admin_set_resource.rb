# frozen_string_literal: true

class AdminSetResource < Hyrax::AdministrativeSet
  include Hyrax::ArResource
  include Hyrax::Permissions::Readable

  # NOTE: Uses ENV rather than Hyrax.config.disable_wings because this line
  # executes at class load time, before Hyrax configuration is fully initialized.
  Hyrax::ValkyrieLazyMigration.migrating(self, from: ::AdminSet) unless ENV["HYRAX_SKIP_WINGS"] == "true"

  include WithPermissionTemplateShim

  def member_of
    Hyrax.query_service.find_inverse_references_by(resource: self, property: :admin_set_id)
  end

  def member_collection_ids
    member_of.map(&:id)
  end
end
