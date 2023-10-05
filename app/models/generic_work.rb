# frozen_string_literal: true

class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include ::Hyrax::BasicMetadata
  include IiifPrint.model_configuration(
    pdf_split_child_model: self
  )

  validates :title, presence: { message: 'Your work must have a title.' }

  self.indexer = GenericWorkIndexer

  prepend OrderAlready.for(:creator)
end
