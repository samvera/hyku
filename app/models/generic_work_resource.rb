# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
class GenericWorkResource < Hyrax::Work
  if Hyrax.config.work_include_metadata?
    include Hyrax::Schema(:core_metadata)
    include Hyrax::Schema(:basic_metadata)
    include Hyrax::Schema(:generic_work_resource)
    include Hyrax::Schema(:bulkrax_metadata)
    include Hyrax::Schema(:with_pdf_viewer)
    include Hyrax::Schema(:with_video_embed)
  end

  include Hyrax::ArResource
  include Hyrax::NestedWorks

  # NOTE: Uses ENV rather than Hyrax.config.disable_wings because this line
  # executes at class load time, before Hyrax configuration is fully initialized.
  Hyrax::ValkyrieLazyMigration.migrating(self, from: GenericWork) unless ENV["HYRAX_SKIP_WINGS"] == "true"

  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWorkResource,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )

  prepend OrderAlready.for(:creator)
end
