# frozen_string_literal: true

Rails.application.config.to_prepare do
  if Hyku.bulkrax_enabled?
    # rubocop:disable Metrics/BlockLength
    Bulkrax.setup do |config|
      # Add local parsers
      # config.parsers += [
      #   { name: 'MODS - My Local MODS parser', class_name: 'Bulkrax::ModsXmlParser', partial: 'mods_fields' },
      # ]

      # Field to use during import to identify if the Work or Collection already exists.
      # Default is 'source'.
      # config.system_identifier_field = 'source'

      # WorkType to use as the default if none is specified in the import
      # Default is the first returned by Hyrax.config.curation_concerns
      # config.default_work_type = MyWork

      # Path to store pending imports
      # config.import_path = 'tmp/imports'

      # Path to store exports before download
      # config.export_path = 'tmp/exports'

      # Server name for oai request header
      # config.server_name = 'my_server@name.com'

      # Field_mapping for establishing a parent-child relationship (FROM parent TO child)
      # This can be a Collection to Work, or Work to Work relationship
      # This value IS NOT used for OAI, so setting the OAI Entries here will have no effect
      # The mapping is supplied per Entry, provide the full class name as a string, eg. 'Bulkrax::CsvEntry'
      # Example:
      #   {
      #     'Bulkrax::RdfEntry'  => 'http://opaquenamespace.org/ns/contents',
      #     'Bulkrax::CsvEntry'  => 'children'
      #   }
      # By default no parent-child relationships are added
      # config.parent_child_field_mapping = { }

      # Field_mapping for establishing a collection relationship (FROM work TO collection)
      # This value IS NOT used for OAI, so setting the OAI parser here will have no effect
      # The mapping is supplied per Entry, provide the full class name as a string, eg. 'Bulkrax::CsvEntry'
      # The default value for CSV is collection
      # Add/replace parsers, for example:
      # config.collection_field_mapping['Bulkrax::RdfEntry'] = 'http://opaquenamespace.org/ns/set'

      # Field mappings
      # NOTE: Bulkrax field mappings are configured on a per-tenant basis in the Account settings.
      # The default set of field mappings that new tenants will be initialized with can be found
      # and/or modified in config/application.rb (Hyku#default_bulkrax_field_mappings)
      # @see config/application.rb
      # @see app/models/concerns/account_settings.rb
      # WARN: Modifying Bulkrax's field mappings in this file will not work as expected
      # @see lib/bulkrax/bulkrax_decorator.rb

      # Because Hyku now uses and assumes Valkyrie to query the repository layer, we need to match the
      # object factory to use Valkyrie.
      config.object_factory = Bulkrax::ValkyrieObjectFactory
      config.factory_class_name_coercer = Bulkrax::FactoryClassFinder::ValkyrieMigrationCoercer

      # To duplicate a set of mappings from one parser to another
      #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
      #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

      # Properties that should not be used in imports/exports. They are reserved for use by Hyrax.
      # config.reserved_properties += ['my_field']
    end
    # rubocop:enable Metrics/BlockLength

    # Sidebar for hyrax 3+ support
    if Object.const_defined?(:Hyrax) && ::Hyrax::DashboardController&.respond_to?(:sidebar_partials)
      Hyrax::DashboardController.sidebar_partials[:repository_content] << "hyrax/dashboard/sidebar/bulkrax_sidebar_additions"
    end

    Bulkrax::CreateRelationshipsJob.update_child_records_works_file_sets = true
  end
end
