# frozen_string_literal: true

class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include ::Hyrax::BasicMetadata
  include IiifPrint.model_configuration(
    pdf_split_child_model: Image
  )

  validates :title, presence: { message: 'Your work must have a title.' }

  self.indexer = GenericWorkIndexer
end
