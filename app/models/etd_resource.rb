# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource EtdResource`
class EtdResource < Hyrax::Work
  # Commented out basic_metadata because these terms were added to etd_resource so we can customize it.
  # include Hyrax::Schema(:basic_metadata)
  include Hyrax::Schema(:etd_resource) unless Hyrax.config.flexible?
  include Hyrax::Schema(:bulkrax_metadata) unless Hyrax.config.flexible?
  include Hyrax::Schema(:with_pdf_viewer) unless Hyrax.config.flexible?
  include Hyrax::Schema(:with_video_embed) unless Hyrax.config.flexible?
  include Hyrax::ArResource
  include Hyrax::NestedWorks

  Hyrax::ValkyrieLazyMigration.migrating(self, from: Etd)

  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWorkResource,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )

  prepend OrderAlready.for(:creator)

  def human_readable_type
    super.upcase
  end
end
