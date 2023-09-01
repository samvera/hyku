# Generated via
#  `rails generate hyrax:work Thesis`
class Thesis < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  self.indexer = ThesisIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }
  
  property :contact_email, predicate: ::RDF::Vocab::VCARD.hasEmail, multiple: false do |index|
    index.as :stored_searchable
  end

  property :contact_phone, predicate: ::RDF::Vocab::VCARD.hasTelephone do |index|
    index.as :stored_searchable
  end

  property :department, predicate: ::RDF::URI.new("http://lib.my.edu/departments"), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
end
