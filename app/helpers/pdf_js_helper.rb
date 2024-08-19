# frozen_string_literal: true

module PdfJsHelper
  def pdf_js_url(path)
    "/pdf.js/viewer.html?file=#{path}##{query_param}"
  end

  def pdf_file_set_presenter(presenter)
    # currently only supports one pdf per work, falls back to the first pdf file set in ordered members
    representative_presenter(presenter) || presenter.file_set_presenters.find(&:pdf?)
  end

  def representative_presenter(presenter)
    presenter.file_set_presenters.find { |file_set_presenter| file_set_presenter.id == presenter.representative_id }
  end

  def query_param
    return unless params[:q]

    "search=#{params[:q]}&phrase=true"
  end

  def render_show_pdf_behavior_checkbox?
    return unless Flipflop.default_pdf_viewer?
    return if params[:id].nil?

    doc = SolrDocument.find params[:id]

    presenter = @_controller.show_presenter.new(doc, current_ability)
    presenter.file_set_presenters.any?(&:pdf?)
  end
end
