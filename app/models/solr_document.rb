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
  attribute :date, Solr::Date, solr_name('alternative_title')
  
  def table_of_contents
    self[Solrizer.solr_name('table_of_contents')]
  end

  def additional_information
    self[Solrizer.solr_name('additional_information')]
  end

  def rights_holder
    self[Solrizer.solr_name('rights_holder')]
  end

  def oer_size
    self[Solrizer.solr_name('oer_size')]
  end

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
    type: 'human_readable_type_tesim',
  )

  def accessibility_feature
    self[Solrizer.solr_name('accessibility_feature')]
  end

  def accessibility_hazard
    self[Solrizer.solr_name('accessibility_hazard')]
  end

  def accessibility_summary
    self[Solrizer.solr_name('accessibility_summary')]
  end
end
