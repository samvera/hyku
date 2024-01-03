# frozen_string_literal: true

class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include ::Hyrax::BasicMetadata
  if ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_IIIF_PRINT', false))
    include IiifPrint.model_configuration(
      pdf_split_child_model: self
    )
  end

  validates :title, presence: { message: 'Your work must have a title.' }

  self.indexer = GenericWorkIndexer

  prepend OrderAlready.for(:creator)
end
