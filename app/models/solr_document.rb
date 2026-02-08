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

  private

  def link_to_item
    return "https://#{first('account_cname_tesim')}/collections/#{id}" if collection?

    Rails.application.routes.url_helpers.send(
      "hyrax_#{first('has_model_ssim').to_s.underscore}_url",
      id,
      host: first('account_cname_tesim'),
      protocol: 'https'
    )
  end

  def link_to_thumbnail
    path = self['thumbnail_path_ss']
    host = first('account_cname_tesim')

    "https://#{host}#{path}"
  end

  # In Blacklight this is a class method, but we need access
  # to the instance's hydra_model to do the reverse lookup
  def field_semantics
    if Hyrax.config.flexible_classes.include?(hydra_model.to_s)
      build_field_semantics(flexible_schema_data)
    elsif hydra_model.respond_to?(:schema)
      build_field_semantics(standard_schema_data)
    else
      basic_mappings
    end
  end

  def build_field_semantics(schema_data)
    schema_data.each_with_object(dc_mappings) do |item, mappings|
      qualified_name = item[:qualified_name]
      next unless qualified_name

      property = qualified_name.split(':').last.to_sym
      index_keys = item[:index_keys]
      next unless mappings.key?(property) && index_keys.present?

      mappings[property] |= index_keys
    end
  end

  def standard_schema_data
    hydra_model.schema.keys.map do |schema_key|
      {
        qualified_name: schema_key.meta.dig('mappings', 'simple_dc_pmh'),
        index_keys: schema_key.meta['index_keys']
      }
    end
  end

  def flexible_schema_data
    m3_data = Hyrax::FlexibleSchema.mappings_data_for('simple_dc_pmh')
    m3_data.map do |_, property_hash|
      {
        qualified_name: property_hash.dig('mappings', 'simple_dc_pmh'),
        index_keys: property_hash['indexing']
      }
    end
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
