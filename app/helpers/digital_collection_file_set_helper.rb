# frozen_string_literal: true

# Helpers for the digital collection theme's file set page.
module DigitalCollectionFileSetHelper
  def dc_file_detail_rows(presenter)
    [
      [:depositor, link_to_profile(presenter.depositor)],
      [:date_uploaded, dc_long_date(presenter.date_uploaded)],
      [:date_modified, dc_long_date(presenter.date_modified)],
      [:fixity, presenter.fixity_check_status],
      [:format, Array(presenter.mime_type).first],
      [:size, dc_file_size(presenter)],
      [:dimensions, dc_file_dimensions(presenter)]
    ].filter_map { |key, value| [t("digital_collection.file_set.details.#{key}"), value] if value.present? }
  end

  def dc_technical_label(presenter, term)
    t("digital_collection.file_set.technical.#{term}", default: presenter.label_for_term(term))
  end

  def dc_long_date(value)
    return if value.blank?

    date = value.is_a?(String) ? Date.parse(value) : value.to_date
    l(date, format: t('digital_collection.collection.date_format'))
  rescue Date::Error
    nil
  end

  private

  def dc_file_size(presenter)
    bytes = Array(presenter.file_size).first.to_i
    number_to_human_size(bytes) if bytes.positive?
  end

  def dc_file_dimensions(presenter)
    width = Array(presenter.width).first
    height = Array(presenter.height).first
    t('digital_collection.file_set.details.dimensions_value', width:, height:) if width.present? && height.present?
  end
end
