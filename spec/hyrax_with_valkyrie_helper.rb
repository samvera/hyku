# frozen_string_literal: true

require 'hyrax/specs/shared_specs/hydra_works'

## We copied the below from Hyrax's spec_helper.
Valkyrie::MetadataAdapter
  .register(Valkyrie::Persistence::Memory::MetadataAdapter.new, :test_adapter)
Valkyrie::MetadataAdapter
  .register(Valkyrie::Persistence::Postgres::MetadataAdapter.new, :postgres_adapter)
Valkyrie::StorageAdapter.register(
  Valkyrie::Storage::VersionedDisk.new(base_path: Rails.root / 'tmp' / 'test_adapter_uploads'),
  :test_disk
)

# The path below is a direct echo of what is in Hyrax.  Yet, with the File.expand_path we're
# referencing Hyku's fixture path.  However, the shared specs might make assumptions about fixtures.
# We could instead use Hyrax::Engine.root.join('spec/fixtures') but would then be bound to those
# files.  I suppose only our tests shall tell.
fixture_base_path = File.expand_path('../fixtures', __FILE__)

Valkyrie::StorageAdapter.register(
  Valkyrie::Storage::Disk.new(base_path: fixture_base_path),
  :fixture_disk
)

require 'hyrax/specs/shared_specs/factories/strategies/valkyrie_resource'
FactoryBot.register_strategy(:valkyrie_create, ValkyrieCreateStrategy)

require 'hyrax/specs/shared_specs/factories/strategies/json_strategy'
FactoryBot.register_strategy(:json, JsonStrategy)
