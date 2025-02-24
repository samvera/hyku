# frozen_string_literal: true

# OVERRIDE Hyrax 5.0.x to also migrate the sipity entity
# This can be removed once code is ported back to Hyrax
module MigrateResourceServiceDecorator
  def call
    original_entity = find_original_entity
    result = super
    migrate_entity(original_entity) if result.success? && original_entity
    result
  end

  def find_original_entity
    resource.work? ? Sipity::Entity(resource) : nil
  end

  def migrate_entity(entity)
    migrated_resource = Hyrax.query_service.find_by(id: resource.id)
    gid = Hyrax::GlobalID(migrated_resource).to_s
    entity.update(proxy_for_global_id: gid) if entity.proxy_for_global_id != gid
  end
end

MigrateResourceService.prepend(MigrateResourceServiceDecorator)
