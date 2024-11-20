module PerTenantFieldMappings
  # OVERRIDE: [Bulkrax v8.2.0] Use tenant-specific field mappings if present
  def field_mappings
    if Site.account.present? && Site.account.bulkrax_field_mappings.present?
      JSON.parse(Site.account.bulkrax_field_mappings).with_indifferent_access
    else
      super
    end
  end
end

Bulkrax.singleton_class.send(:prepend, PerTenantFieldMappings)
