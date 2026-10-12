# frozen_string_literal: true

module Hyku
  # Must be prepended AFTER IiifPrint::TenantConfig::WorkShowPresenterDecorator, which
  # owns #iiif_viewer? and is itself prepended onto Hyku::WorkShowPresenter. Defining
  # these methods in that class body instead would leave them shadowed and never run.
  module MediaViewerBehavior
    # The viewers reached through hyrax/base/iiif_viewers/. pdf_js is deliberately absent:
    # it takes a file URL rather than a manifest, so it routes through #show_pdf_viewer?.
    IIIF_VIEWERS = %i[universal_viewer clover ramp].freeze

    def iiif_viewer
      IIIF_VIEWERS.include?(chosen_viewer) ? chosen_viewer : super
    end

    def iiif_viewer?
      return false if chosen_viewer == :pdf_js
      return super unless IIIF_VIEWERS.include?(chosen_viewer)

      # An explicit choice bypasses the tenant-level checks in super (image server,
      # media type, viewable members): the depositor has already made the call.
      representative_id.present? && representative_presenter.present?
    end

    def show_pdf_viewer?
      # Wins over the tenant-wide default_pdf_viewer flag and the older per-work
      # show_pdf_viewer boolean, both of which super still honors for unset works.
      return true if chosen_viewer == :pdf_js && file_set_presenters.any?(&:pdf?)

      super
    end

    private

    # Gated here rather than per method: with the flag off every override falls through
    # to super, so the tenant behaves as though the feature were absent.
    def chosen_viewer
      return unless Flipflop.per_work_media_viewer?

      solr_document['media_viewer_ssi'].presence&.to_sym
    end
  end
end
