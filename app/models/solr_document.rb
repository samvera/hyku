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

  attribute :extent, Solr::Array, solr_name('extent')
  attribute :rendering_ids, Solr::Array, solr_name('hasFormat', :symbol)
  attribute :alternative_title, Solr::String, solr_name('alternative_title')
  attribute :date, Solr::String, solr_name('date')
  attribute :audience, Solr::Array, solr_name('audience')
  attribute :education_level, Solr::Array, solr_name('education_level')
  attribute :learning_resource_type, Solr::Array, solr_name('learning_resource_type')
  attribute :table_of_contents, Solr::String, solr_name('table_of_contents')
  attribute :additional_information, Solr::String, solr_name('additional_information')
  attribute :rights_holder, Solr::String, solr_name('rights_holder')
  attribute :oer_size, Solr::String, solr_name('oer_size')
  attribute :accessibility_summary, Solr::String, solr_name('accessibility_summary')
  attribute :accessibility_feature, Solr::Array, solr_name('accessibility_feature')
  attribute :accessibility_hazard, Solr::Array, solr_name('accessibility_hazard')
  attribute :previous_version, Solr::String, solr_name('previous_version')
  attribute :discipline, Solr::Array, solr_name('discipline')

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

end
