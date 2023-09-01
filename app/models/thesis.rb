# Generated via
#  `rails generate hyrax:work Thesis`
class Thesis < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  self.indexer = ThesisIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
end

# The GenericWork class is generated with some default metadata, but we want to
# update it with our own metadata. 
# 
# BASIC AND CORE METADATA
# Basic metadata are the default properties for all works.
# ref: 
# https://github.com/samvera/hyrax/blob/1-0-stable/app/models/concerns/hyrax/basic_metadata.rb
# Core metadata properties are required and should never be removed! 
# ref: 
# https://github.com/samvera/hyrax/blob/1-0-stable/app/models/concerns/hyrax/required_metadata.rb
# 
# EXERCISE: EXTEND THE MODEL
# Hint: Look at the basic metadata to see how the current properties are defined.
# 1. Add a new single-value property called 'contact_email'
# predicate: '::RDF::Vocab::VCARD.hasEmail'
# index as ':stored_searchable'
# 2. Add a new multi-value property called 'contact_phone'
# predicate: '::RDF::Vocab::VCARD.hasTelephone'
# index as ':stored_searchable, :facetable'
# 3. Add a new property with a controlled vocabulary called 'department'
# predicate: '::RDF::URI.new("http://lib.my.edu/departments")'
# index as ':stored_searchable, :facetable'