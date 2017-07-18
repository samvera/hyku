module HasRendering
  extend ActiveSupport::Concern

  included do
    # TODO: this relationship allows multiples but might need other code elsewhere to make it work in the forms etc.
    has_and_belongs_to_many :rendering,
             predicate: ::RDF::URI.new("http://london.ac.uk/ontologies/terms#hasRendering"),
             class_name: 'ActiveFedora::Base'
  end
end
