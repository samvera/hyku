# frozen_string_literal: true

module Bulkrax
  module PerTenantFieldMappingDecorator
    # OVERRIDE: [Bulkrax v8.2.0] Use tenant-specific field mappings if present
    def field_mappings
      if Site.account.present? && Site.account.bulkrax_field_mappings.present?
        JSON.parse(Site.account.bulkrax_field_mappings).with_indifferent_access
      else
        Hyku.default_bulkrax_field_mappings.presence || super
      end
    end
  end
end
Bulkrax.singleton_class.send(:prepend, Bulkrax::PerTenantFieldMappingDecorator)
