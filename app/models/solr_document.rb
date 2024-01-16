# frozen_string_literal: true

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
  attribute :video_embed, Solr::String, 'video_embed_tesim'

  field_semantics.merge!(
    contributor: 'contributor_tesim',
    creator: 'creator_tesim',
    date: 'date_created_tesim',
    description: 'description_tesim',
    identifier: 'identifier_tesim',
    language: 'language_tesim',
    publisher: 'publisher_tesim',
    relation: 'nesting_collection__pathnames_ssim',
    rights: 'rights_statement_tesim',
    subject: 'subject_tesim',
    title: 'title_tesim',
    type: 'human_readable_type_tesim'
  )

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
    query("member_ids_ssim: #{id}", rows: 1000)
      .map { |res| ::SolrDocument.new(res) }
  end

  # Query solr using POST so that the query doesn't get too large for a URI
  def query(query, **opts)
    result = Hyrax::SolrService.post(query, **opts)
    result.fetch('response').fetch('docs', [])
  end
end
