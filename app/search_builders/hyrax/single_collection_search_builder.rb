# NOTE: Override file from Hyrax v2.9.0 to change the parent class.
# This allows us to inherit the overwritten #gated_discovery_filters
# method and apply those changes to the SingleCollectionSearchBuilder.
# See #gated_discovery_filters in config/initializers/permissions_overrides.rb
module Hyrax
  # Override - changed ::SearchBuilder to CollectionSearchBuilder
  class SingleCollectionSearchBuilder < CollectionSearchBuilder
    include SingleResult
  end
end
