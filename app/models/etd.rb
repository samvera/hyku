# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work Etd`

##
# Electronic Thesis and Dissertation
#
# @see https://www.wikidata.org/wiki/Q115121540
class Etd < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWork,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )
  include PdfBehavior
  include VideoEmbedBehavior

  self.indexer = EtdIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  property :advisor, predicate: ::RDF::URI('https://hykucommons.org/terms/advisor') do |index|
    index.as :stored_searchable
  end

  property :bulkrax_identifier, predicate: ::RDF::URI("https://hykucommons.org/terms/bulkrax_identifier"), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :committee_member, predicate: ::RDF::URI('https://hykucommons.org/terms/committee_member') do |index|
    index.as :stored_searchable
  end

  property :degree_discipline, predicate: ::RDF::URI('https://hykucommons.org/terms/degree_discipline') do |index|
    index.as :stored_searchable
  end

  property :degree_grantor, predicate: ::RDF::URI('https://hykucommons.org/terms/degree_grantor') do |index|
    index.as :stored_searchable
  end

  property :degree_level, predicate: ::RDF::URI('https://hykucommons.org/terms/degree_level') do |index|
    index.as :stored_searchable
  end

  property :degree_name, predicate: ::RDF::URI('https://hykucommons.org/terms/degree_name') do |index|
    index.as :stored_searchable
  end

  property :department, predicate: ::RDF::URI('https://hykucommons.org/terms/department') do |index|
    index.as :stored_searchable
  end

  property :format, predicate: ::RDF::Vocab::DC.format do |index|
    index.as :stored_searchable
  end

  property :additional_information, predicate: ::RDF::Vocab::DC.accessRights do |index|
    index.as :stored_searchable
  end

  property :bibliographic_citation, predicate: ::RDF::Vocab::DC.bibliographicCitation do |index|
    index.as :stored_searchable
  end

  property :admin_note, predicate: ::RDF::Vocab::SCHEMA.positiveNotes, multiple: false do |index|
    index.as :stored_searchable
  end

  property :date, predicate: ::RDF::URI("https://hykucommons.org/terms/date"), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
  # This line must be kept below all others that set up properties,
  # including `include ::Hyrax::BasicMetadata`. All properties must
  # be declared before their values can be ordered.
  include OrderMetadataValues

  # These needed to be added again in order to enable destroy for based_near, even though they are in Hyrax::BasicMetadata.
  # the OrderAlready OrderMetadataValues above somehow prevents them from running
  id_blank = proc { |attributes| attributes[:id].blank? }
  class_attribute :controlled_properties
  self.controlled_properties = [:based_near]
  accepts_nested_attributes_for :based_near, reject_if: id_blank, allow_destroy: true
end
