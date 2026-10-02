# frozen_string_literal: true

# OVERRIDE IiifPrint v3.1.1 to build a flexible work's manifest metadata from its m3 profile

module IiifPrintDecorator
  def manifest_metadata_from(work:, presenter:)
    return super unless Hyku::ProfileManifestMetadata.applies_to?(work)

    # OVERRIDE
    base_url = presenter.try(:base_url) || presenter.try(:request)&.base_url
    Hyku::ProfileManifestMetadata.for_work(work, base_url:)
  end
end

IiifPrint.singleton_class.prepend(IiifPrintDecorator)
