# frozen_string_literal: true
# Set flexible metadata flags based on global flag

flexible = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYRAX_FLEXIBLE', 'true'))
if flexible
  ENV['HYRAX_FLEXIBLE_CLASSES'] = %w[
    AdminSetResource
    CollectionResource
    Hyrax::FileSet
    GenericWorkResource
    ImageResource
    EtdResource
    OerResource
  ].join(',')
  ENV['HYRAX_DISABLE_INCLUDE_METADATA'] = 'true'
else
  ENV['HYRAX_FLEXIBLE_CLASSES'] = ''
  ENV['HYRAX_DISABLE_INCLUDE_METADATA'] = 'false'
end
