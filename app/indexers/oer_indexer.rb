# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Oer`
class OerIndexer < AppIndexer
  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['admin_note_tesim'] = object.admin_note
    end
  end
end
