# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource ImageResource`
class ImageResource < Hyrax::Work
  include Hyrax::Schema(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::Schema(:bulkrax_metadata) unless Hyrax.config.flexible?
  include Hyrax::Schema(:image_resource) unless Hyrax.config.flexible?
  include Hyrax::Schema(:with_pdf_viewer) unless Hyrax.config.flexible?
  include Hyrax::Schema(:with_video_embed) unless Hyrax.config.flexible?
  include Hyrax::ArResource
  include Hyrax::NestedWorks

  Hyrax::ValkyrieLazyMigration.migrating(self, from: Image)

  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWorkResource,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )

  prepend OrderAlready.for(:creator)
end
