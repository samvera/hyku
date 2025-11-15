# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource EtdResource`
class EtdResource < Hyrax::Work
  if Hyrax.config.work_include_metadata?
    include Hyrax::Schema(:core_metadata)
    # Commented out basic_metadata because these terms were added to etd_resource so we can customize it.
    # include Hyrax::Schema(:basic_metadata)
    include Hyrax::Schema(:etd_resource)
    include Hyrax::Schema(:bulkrax_metadata)
    include Hyrax::Schema(:with_pdf_viewer)
    include Hyrax::Schema(:with_video_embed)
  end

  include Hyrax::ArResource
  include Hyrax::NestedWorks

  Hyrax::ValkyrieLazyMigration.migrating(self, from: Etd)

  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWorkResource,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )

  prepend OrderAlready.for(:creator) unless Hyrax.config.flexible?

  def human_readable_type
    super.upcase
  end
end
