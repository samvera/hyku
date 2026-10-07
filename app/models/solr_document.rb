# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument

  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models.
  use_extension(Hydra::ContentNegotiation)

  attribute :account_cname, Solr::Array, 'account_cname_tesim'
  attribute :account_institution_name, Solr::Array, 'account_institution_name_ssim'
  attribute :extent, Solr::Array, 'extent_tesim'
  attribute :rendering_ids, Solr::Array, 'hasFormat_ssim'
  attribute :audience, Solr::Array, 'audience_tesim'
  attribute :education_level, Solr::Array, 'education_level_tesim'
  attribute :learning_resource_type, Solr::Array, 'learning_resource_type_tesim'
  attribute :table_of_contents, Solr::Array, 'table_of_contents_tesim'
  attribute :additional_information, Solr::String, 'additional_information_tesi'
  attribute :rights_holder, Solr::Array, 'rights_holder_tesim'
  attribute :oer_size, Solr::Array, 'oer_size_tesim'
  attribute :accessibility_summary, Solr::String, 'accessibility_summary_tesim'
  attribute :accessibility_feature, Solr::Array, 'accessibility_feature_tesim'
  attribute :accessibility_hazard, Solr::Array, 'accessibility_hazard_tesim'
  attribute :previous_version_id, Solr::String, 'previous_version_id_tesi'
  attribute :newer_version_id, Solr::String, 'newer_version_id_tesi'
  attribute :alternate_version_id, Solr::String, 'alternate_version_id_tesi'
  attribute :related_item_id, Solr::String, 'related_item_id_tesi'
  attribute :discipline, Solr::Array, 'discipline_tesim'
  attribute :advisor, Solr::Array, 'advisor_tesim'
  attribute :committee_member, Solr::Array, 'committee_member_tesim'
  attribute :degree_discipline, Solr::Array, 'degree_discipline_tesim'
  attribute :degree_grantor, Solr::Array, 'degree_grantor_tesim'
  attribute :degree_level, Solr::Array, 'degree_level_tesim'
  attribute :degree_name, Solr::Array, 'degree_name_tesim'
  attribute :department, Solr::Array, 'department_tesim'
  attribute :format, Solr::Array, 'format_tesim'
  attribute :title_ssi, Solr::Array, 'title_ssi_tesim'
  attribute :bibliographic_citation, Solr::String, 'bibliographic_citation_tesim'
  attribute :collection_subtitle, Solr::String, 'collection_subtitle_tesi'
  attribute :admin_note, Solr::String, 'admin_note_tesim'
  attribute :contributing_library, Solr::String, 'contributing_library_tesim'
  attribute :library_catalog_identifier, Solr::String, 'library_catalog_identifier_tesim'
  attribute :chronology_note, Solr::String, 'chronology_note_tesim'
  attribute :based_near, Solr::Array, 'based_near_tesim'

  # OVERRIDE Blacklight v7.35.0 to find properties from schema metadata
  #   and to add show page and thumbnail links to identifier
  def to_semantic_values
    @semantic_value_hash ||= field_semantics.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(key, field_names), hash|
      ##
      # Handles single string field_name or an array of field_names
      value = Array.wrap(field_names).map { |field_name| self[field_name] }.flatten.compact

      # Make single and multi-values all arrays, so clients
      # don't have to know.
      hash[key] = value unless value.empty?
    end

    @semantic_value_hash[:identifier] << link_to_item
    @semantic_value_hash[:identifier] << link_to_thumbnail if self['thumbnail_path_ss']

    @semantic_value_hash
  end

  def show_pdf_viewer
    # NOTE: We want to move towards persisting a boolean.  In the ActiveFedora implementation we are
    # storing things as Strings; in Valkyrie we want to move towards boolean.  This logic is
    # necessary as we move the underlying persistence towards a boolean field.
    value = if key?('show_pdf_viewer_bsi')
              self['show_pdf_viewer_bsi']
            else
              self['show_pdf_viewer_tsi'] ||
                Array.wrap(self['show_pdf_viewer_tesim']).first
            end
    # Nil is not cast to false in the following Boolean operation.
    return false if value.nil?
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def show_pdf_download_button
    # NOTE: We want to move towards persisting a boolean.  In the ActiveFedora implementation we are
    # storing things as Strings; in Valkyrie we want to move towards boolean.  This logic is
    # necessary as we move the underlying persistence towards a boolean field.
    value = if key?('show_pdf_download_button_bsi')
              self['show_pdf_download_button_bsi']
            else
              self['show_pdf_download_button_tsi'] ||
                Array.wrap(self['show_pdf_download_button_tesim']).first
            end
    # Nil is not cast to false in the following Boolean operation.
    return false if value.nil?
    ActiveModel::Type::Boolean.new.cast(value)
  end

  # @return [Array<SolrDocument>] a list of solr documents in no particular order
  def load_parent_docs
    query("member_ids_ssim:#{id}", rows: 1000)
      .map { |res| ::SolrDocument.new(res) }
  end

  # Query solr using POST so that the query doesn't get too large for a URI
  def query(query, **opts)
    result = Hyrax::SolrService.post(query, **opts)
    result.fetch('response').fetch('docs', [])
  end

  def video_embed
    self['video_embed_tesi'] || first('video_embed_tesim')
  end

  def media_viewer
    self['media_viewer_ssi']
  end

  # The OAI-PMH mods format renders a record through this method
  def to_mods
    Hyku::Mods::RecordBuilder.new(
      self,
      mappings: schema_data_for(Hyku::Mods::MAPPING_KEY).to_a,
      compounds: compound_schema_data_for(Hyku::Mods::MAPPING_KEY).to_a,
      item_url: link_to_item,
      thumbnail_url: (link_to_thumbnail if real_thumbnail?)
    ).to_xml
  end

  private

  def link_to_item
    host = first('account_cname_tesim') || Site.account&.cname
    return nil unless host
    return "https://#{host}/collections/#{id}" if collection?

    Rails.application.routes.url_helpers.send(
      "hyrax_#{first('has_model_ssim').to_s.underscore}_url",
      id,
      host: host,
      protocol: 'https'
    )
  rescue StandardError
    nil
  end

  def link_to_thumbnail
    path = self['thumbnail_path_ss']
    host = first('account_cname_tesim')

    "https://#{host}#{path}"
  end

  # A record without files gets a placeholder: an asset-pipeline image, or the tenant's default
  def real_thumbnail?
    path = self['thumbnail_path_ss']
    return false if path.blank? || path.start_with?('/assets/')

    [Site.instance.default_work_image, Site.instance.default_collection_image].none? { |image| image&.url == path }
  end

  # In Blacklight this is a class method, but we need access
  # to the instance's hydra_model to do the reverse lookup
  def field_semantics
    schema_data = schema_data_for('simple_dc_pmh')
    schema_data ? build_field_semantics(schema_data) : basic_mappings
  end

  # @return [Array<Hash>, nil] each property mapped under mapping_key, with its mapping and index
  #   keys: from the flexible metadata profile (across all its classes) or the model's schema;
  #   nil when the model has neither
  def schema_data_for(mapping_key)
    if Hyrax.config.flexible_classes.include?(hydra_model.to_s)
      flexible_schema_data(mapping_key)
    elsif hydra_model.respond_to?(:schema)
      standard_schema_data(mapping_key)
    end
  end

  # @return [Array<Hash>, nil] each compound with a sub-property mapped under mapping_key, as
  #   +{ compound:, subproperties: [{ key:, property:, mapping: }] }+, where +key+ names the
  #   sub-property in the compound's indexed entries and +property+ is its profile property
  #   (flexible metadata only); nil when the model has neither source
  def compound_schema_data_for(mapping_key)
    if Hyrax.config.flexible_classes.include?(hydra_model.to_s)
      flexible_compound_data(mapping_key)
    elsif hydra_model.respond_to?(:schema)
      standard_compound_data(mapping_key)
    end
  end

  def build_field_semantics(schema_data)
    schema_data.each_with_object(dc_mappings) do |item, mappings|
      property = item[:mapping].split(':').last.to_sym
      index_keys = Array(item[:index_keys]).select { |k| k.to_s.end_with?('_tesim') }
      next unless mappings.key?(property) && index_keys.present?

      mappings[property] |= index_keys
    end
  end

  def standard_schema_data(mapping_key)
    hydra_model.schema.keys.filter_map do |schema_key|
      mapping = schema_key.meta.dig('mappings', mapping_key)
      next unless mapping

      { property: schema_key.name.to_s, mapping:, index_keys: schema_key.meta['index_keys'] }
    end
  end

  def flexible_schema_data(mapping_key)
    m3_data = Hyrax::FlexibleSchema.mappings_data_for(mapping_key)
    m3_data.map do |property, property_hash|
      {
        property: property.to_s,
        mapping: property_hash.dig('mappings', mapping_key),
        index_keys: property_hash['indexing']
      }
    end
  end

  # Hyrax's schema loaders fold a compound's sub-properties into the parent's meta, keyed as
  # they appear in its indexed entries
  def standard_compound_data(mapping_key)
    hydra_model.schema.keys.filter_map do |schema_key|
      subproperties = schema_key.meta['subproperties'].to_h.map { |key, config| [key, nil, config] }
      compound_data(schema_key.name, subproperties, mapping_key)
    end
  end

  # The profile lists each sub-property as its own property, naming its parent compound
  def flexible_compound_data(mapping_key)
    properties = Hyrax::FlexibleSchema.current_version&.dig('properties').to_h
    by_parent = properties.each_with_object({}) do |(property, config), parents|
      next unless config.is_a?(Hash)

      Array(config.dig('available_on', 'properties')).each do |parent|
        (parents[parent.to_s] ||= []) << [config['name'] || property, property, config]
      end
    end
    by_parent.filter_map { |parent, subproperties| compound_data(parent, subproperties, mapping_key) }
  end

  def compound_data(compound, subproperties, mapping_key)
    mapped = subproperties.filter_map do |key, property, config|
      mapping = config.is_a?(Hash) && config.dig('mappings', mapping_key)
      { key: key.to_s, property: property&.to_s, mapping: } if mapping
    end
    { compound: compound.to_s, subproperties: mapped } if mapped.any?
  end

  def basic_mappings
    {
      contributor: ['contributor_tesim'],
      coverage: [],
      creator: ['creator_tesim'],
      date: ['date_created_tesim'],
      description: ['description_tesim'],
      format: ['format_tesim'],
      identifier: ['identifier_tesim'],
      language: ['language_tesim'],
      publisher: ['publisher_tesim'],
      relation: ['nesting_collection__pathnames_ssim'],
      rights: ['rights_statement_tesim', 'rights_notes_tesim', 'license_tesim'],
      source: [],
      subject: ['subject_tesim'],
      title: ['title_tesim'],
      type: ['human_readable_type_tesim']
    }
  end

  def dc_mappings
    @dc_mappings ||= {
      contributor: [],
      coverage: [],
      creator: [],
      date: [],
      description: [],
      format: [],
      identifier: [],
      language: [],
      publisher: [],
      relation: [],
      rights: [],
      source: [],
      subject: [],
      title: ['title_tesim'], # adding title_tesim since this is a core metadata property which will always be available
      type: []
    }
  end
end
# rubocop:enable Metrics/ClassLength
