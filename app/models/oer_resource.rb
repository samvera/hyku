# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource OerResource`
class OerResource < Hyrax::Work
  if Hyrax.config.work_include_metadata?
    include Hyrax::Schema(:core_metadata)
    # Commented out basic_metadata because these terms were added to etd_resource so we can customize it.
    # include Hyrax::Schema(:basic_metadata)
    include Hyrax::Schema(:oer_resource)
    include Hyrax::Schema(:bulkrax_metadata)
    include Hyrax::Schema(:with_pdf_viewer)
    include Hyrax::Schema(:with_video_embed)
  end

  include Hyrax::ArResource
  include Hyrax::NestedWorks

  Hyrax::ValkyrieLazyMigration.migrating(self, from: Oer)

  include IiifPrint.model_configuration(
    pdf_split_child_model: GenericWorkResource,
    pdf_splitter_service: IiifPrint::TenantConfig::PdfSplitter
  )

  prepend OrderAlready.for(:creator) unless Hyrax.config.flexible?

  def previous_version
    @previous_version ||= Hyrax.query_service.find_many_by_ids(ids: previous_version_id) if previous_version_id.present?
  end

  def newer_version
    @newer_version ||= Hyrax.query_service.find_many_by_ids(ids: newer_version_id) if newer_version_id.present?
  end

  def alternate_version
    @alternate_version ||= Hyrax.query_service.find_many_by_ids(ids: alternate_version_id) if alternate_version_id.present?
  end

  def related_item
    @related_item ||= Hyrax.query_service.find_many_by_ids(ids: related_item_id) if related_item_id.present?
  end

  def human_readable_type
    super.upcase
  end
end
