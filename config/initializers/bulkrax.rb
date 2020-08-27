# frozen_string_literal: true

Bulkrax.setup do |config|
  # Add local parsers
  # config.parsers += [
  #   { name: 'MODS - My Local MODS parser', class_name: 'Bulkrax::ModsXmlParser', partial: 'mods_fields' },
  # ]

  config.parsers += [
    { name: 'CSV - Open Educational Resources (OER)', class_name: 'Bulkrax::OerCsvParser', partial: 'oer_csv_fields' }
  ]

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
  # Create a completely new set of mappings by replacing the whole set as follows
  #   config.field_mappings = {
  #     "Bulkrax::OaiDcParser" => { **individual field mappings go here*** }
  #   }
  basic_csv_mappings = {
    'title' => { from: ['title'], split: true },
    'creator' => { from: ['creator'], split: true },
    'keyword' => { from: ['keyword'], split: true },
    'description' => { from: ['description'], split: true },
    'subject' => { from: ['subject'], split: true },
    'license' => { from: ['license'], split: '\|' },
    'contributor' => { from: ['contributor'], split: true },
    'publisher' => { from: ['publisher'], split: true },
    'date_created' => { from: ['date_created'], split: true },
    'language' => { from: ['language'], split: true },
    'identifier' => { from: ['identifier'], split: true },
    'based_near' => { from: ['location'], split: '\|' },
    'related_url' => { from: ['related_url'], split: '\|' },
    'resource_type' => { from: ['type'], split: true },
    'file' => { from: ['item'], split: true }
  }

  config.field_mappings['Bulkrax::CsvParser'] = basic_csv_mappings

  config.field_mappings['Bulkrax::OerCsvParser'] = basic_csv_mappings.merge({
    'learning_resource_type' => { from: ['learning_resource_type'], split: true },
    'alternative_title' => { from: ['alternative_title'], split: true },
    'education_level' => { from: ['education_level'], split: true },
    'audience' => { from: ['audience'], split: true },
    'discipline' => { from: ['discipline'], split: true },
    'date' => { from: ['date'], split: true },
    'table_of_contents' => { from: ['table_of_contents'], split: true },
    'oer_size' => { from: ['oer_size'], split: true },
    'rights_holder' => { from: ['rights_holder'], split: true },
    'accessibility_feature' => { from: ['accessibility_feature'], split: true },
    'accessibility_hazard' => { from: ['accessibility_hazard'], split: true },
    'accessibility_summary' => { from: ['accessibility_summary'] },
    'previous_version' => { from: ['previous_version'], split: true },
    'newer_version' => { from: ['newer_version'], split: true },
    'alternate_version' => { from: ['alternate_version'], split: true },
    'related_item' => { from: ['related_item'], split: true }
  })

  # Add to, or change existing mappings as follows
  #   e.g. to exclude date
  #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }

  # To duplicate a set of mappings from one parser to another
  #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
  #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  # Properties that should not be used in imports/exports. They are reserved for use by Hyrax.
  # config.reserved_properties += ['my_field']
end
