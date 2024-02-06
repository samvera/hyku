# frozen_string_literal: true

class GenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include PdfBehavior
  include VideoEmbedBehavior

  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWork,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )

  validates :title, presence: { message: 'Your work must have a title.' }

  include ::Hyrax::BasicMetadata
  self.indexer = GenericWorkIndexer

  prepend OrderAlready.for(:creator)
end
