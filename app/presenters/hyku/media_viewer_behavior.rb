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
      return @chosen_iiif_viewable if defined?(@chosen_iiif_viewable)

      # An explicit choice bypasses the tenant-level checks in super (image server, media
      # type) but still needs something the viewer can draw. The PDF itself never counts,
      # even under IIIF Print: until it is split, its pages are not child works yet.
      @chosen_iiif_viewable = representative_id.present? && representative_presenter.present? &&
                              (readable_iiif_file_set? || child_works_viewable?)
    end

    def show_pdf_viewer?
      return super unless pdf_js_chosen? || unshowable_iiif_choice?

      # Wins over the tenant-wide default_pdf_viewer flag and the older per-work
      # show_pdf_viewer boolean, both of which super still honors for unset works.
      file_set_presenters.any?(&:pdf?) || super
    end

    private

    # Gated here rather than per method: with the flag off every override falls through
    # to super, so the tenant behaves as though the feature were absent.
    def chosen_viewer
      return unless Flipflop.per_work_media_viewer?

      solr_document['media_viewer_ssi'].presence&.to_sym
    end

    def pdf_js_chosen?
      chosen_viewer == :pdf_js
    end

    def readable_iiif_file_set?
      file_set_presenters.any? do |file_set|
        (file_set.try(:image?) || file_set.try(:audio?) || file_set.try(:video?)) && current_ability.can?(:read, file_set.id)
      end
    end

    # A IIIF viewer was chosen, but the work has nothing it can draw, so a PDF falls back to PDF.js.
    def unshowable_iiif_choice?
      IIIF_VIEWERS.include?(chosen_viewer) && !iiif_viewer?
    end
  end
end
