# frozen_string_literal: true

if ENV.fetch('HYKU_BULKRAX_ENABLED', 'true') == 'true'
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
    # Create a completely new set of mappings by replacing the whole set as follows
    #   config.field_mappings = {
    #     "Bulkrax::OaiDcParser" => { **individual field mappings go here*** }
    #   }

    # Add to, or change existing mappings as follows
    #   e.g. to exclude date
    #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }

    default_field_mapping = {
      'abstract' => { from: ['abstract'], split: true },
      'alternative_title' => { from: ['alternative_title'], split: /\s*[|]\s*/ },
      'based_near' => { from: ['based_near'], split: true },
      'bibliographic_citation' => { from: ['bibliographic_citation'], split: true },
      'contributor' => { from: ['contributor'], split: true },
      'create_date' => { from: ['create_date'], split: true },
      'children' => { from: ['children'], related_children_field_mapping: true },
      'creator' => { from: ['creator'], split: true },
      'date_created' => { from: ['date_created'], split: true },
      'description' => { from: ['description'], split: true },
      'extent' => { from: ['extent'], split: true },
      'file' => { from: ['file'], split: /\s*[|]\s*/ },
      'identifier' => { from: ['identifier'], split: true },
      'keyword' => { from: ['keyword'], split: true },
      'language' => { from: ['language'], split: true },
      'license' => { from: ['license'], split: /\s*[|]\s*/ },
      'modified_date' => { from: ['modified_date'], split: true },
      'parents' => { from: ['parents'], related_parents_field_mapping: true },
      'publisher' => { from: ['publisher'], split: true },
      'related_url' => { from: ['related_url'], split: /\s* [|]\s*/ },
      'remote_files' => { from: ['remote_files'], split: /\s*[|]\s*/ },
      'resource_type' => { from: ['resource_type'], split: true },
      'rights_notes' => { from: ['rights_notes'], split: true },
      'source' => { from: ['source'], split: true },
      'subject' => { from: ['subject'], split: true },
      'title' => { from: ['title'], split: /\s*[|]\s*/ }
    }

    config.field_mappings["Bulkrax::BagitParser"] = default_field_mapping.merge({
                                                                                  # add or remove custom mappings for this parser here
                                                                                })

    config.field_mappings["Bulkrax::CsvParser"] = default_field_mapping.merge({
                                                                                # add or remove custom mappings for this parser here
                                                                              })

    config.field_mappings["Bulkrax::OaiDcParser"] = default_field_mapping.merge({
                                                                                  # add or remove custom mappings for this parser here
                                                                                })

    config.field_mappings["Bulkrax::OaiQualifiedDcParser"] = default_field_mapping.merge({
                                                                                           # add or remove custom mappings for this parser here
                                                                                         })

    config.field_mappings["Bulkrax::XmlParser"] = default_field_mapping.merge({
                                                                                # add or remove custom mappings for this parser here
                                                                              })

    # To duplicate a set of mappings from one parser to another
    #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
    #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

    # Properties that should not be used in imports/exports. They are reserved for use by Hyrax.
    # config.reserved_properties += ['my_field']
  end
  # rubocop:enable Metrics/BlockLength

  Bulkrax::CreateRelationshipsJob.update_child_records_works_file_sets = true
end
