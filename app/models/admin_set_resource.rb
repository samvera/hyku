# frozen_string_literal: true

class AdminSetResource < Hyrax::AdministrativeSet
  include Hyrax::ArResource
  include Hyrax::Permissions::Readable
  Hyrax::ValkyrieLazyMigration.migrating(self, from: ::AdminSet)

  include WithPermissionTemplateShim

  def member_of
    Hyrax.query_service.find_inverse_references_by(resource: self, property: :admin_set_id)
  end

  def member_collection_ids
    member_of.map(&:id)
  end
end
