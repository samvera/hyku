# frozen_string_literal: true

Bulkrax.setup do |config|
  # Add local parsers
  # config.parsers += [
  #   { name: 'MODS - My Local MODS parser', class_name: 'Bulkrax::ModsXmlParser', partial: 'mods_fields' },
  # ]

  config.parsers += [
    { name: 'CSV - Open Educational Resources (OER)', class_name: 'Bulkrax::OerCsvParser', partial: 'oer_csv_fields' },
    { name: 'CSV - Electronic Theses & Dissertations (ETD)', class_name: 'Bulkrax::EtdCsvParser', partial: 'etd_csv_fields' }
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
    'title' => { from: ['title'], split: /[;\|]/ },
    'creator' => { from: ['creator'], split: '\|' },
    'keyword' => { from: ['keyword'], split: '\|' },
    'description' => { from: ['description'], split: '\|' },
    'subject' => { from: ['subject'], split: '\|' },
    'license' => { from: ['license'], split: '\|' },
    'contributor' => { from: ['contributor'], split: '\|' },
    'publisher' => { from: ['publisher'], split: '\|' },
    'date_created' => { from: ['date_created'], split: '\|' },
    'language' => { from: ['language'], split: '\|' },
    'identifier' => { from: ['identifier'], split: '\|' },
    'based_near' => { from: ['location'], split: '\|' },
    'related_url' => { from: ['related_url'], split: '\|' },
    'resource_type' => { from: ['type'], split: '\|' },
    'file' => { from: ['item'], split: '\|' }
  }

  config.field_mappings['Bulkrax::CsvParser'] = basic_csv_mappings

  config.field_mappings['Bulkrax::OerCsvParser'] = basic_csv_mappings.merge({
    'learning_resource_type' => { from: ['learning_resource_type'], split: '\|' },
    'alternative_title' => { from: ['alternative_title'], split: '\|' },
    'education_level' => { from: ['education_level'], split: '\|' },
    'audience' => { from: ['audience'], split: '\|' },
    'discipline' => { from: ['discipline'], split: '\|' },
    'date' => { from: ['date'], split: '\|' },
    'table_of_contents' => { from: ['table_of_contents'], split: '\|' },
    'oer_size' => { from: ['oer_size'], split: '\|' },
    'rights_holder' => { from: ['rights_holder'], split: '\|' },
    'accessibility_feature' => { from: ['accessibility_feature'], split: '\|' },
    'accessibility_hazard' => { from: ['accessibility_hazard'], split: '\|' },
    'accessibility_summary' => { from: ['accessibility_summary'] },
    'previous_version' => { from: ['previous_version'], split: '\|' },
    'newer_version' => { from: ['newer_version'], split: '\|' },
    'alternate_version' => { from: ['alternate_version'], split: '\|' },
    'related_item' => { from: ['related_item'], split: '\|' }
  })

  config.field_mappings['Bulkrax::EtdCsvParser'] = basic_csv_mappings.merge({
    'committee_member' => { from: ['committee_member'], split: '\|' },
    'creator' => { from: ['author'], split: '\|' },
    'date_created' => { from: ['date'], split: '\|' },
    'degree_discipline' => { from: ['discipline'], split: '\|' },
    'degree_grantor' => { from: ['grantor'], split: '\|' },
    'degree_level' => { from: ['level'], split: '\|' },
    'degree_name' => { from: ['degree'], split: '\|' },
    'related_url' => { from: ['relation'], split: '\|' },
    'resource_type' => { from: ['type'], split: '\|' },
    'rights_statement' => { from: ['rights'], split: '\|' }
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
