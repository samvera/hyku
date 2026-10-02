# frozen_string_literal: true

module Hyku
  # Derive plain integer years from EDTF-ish date values for indexing into a
  # numeric Solr field that Blacklight's range limit can facet and chart.
  module DateRangeYears
    module_function

    MAX_INTERVAL_SPAN = 1000
    LEADING_YEAR = /\A\s*(\d{4}|\d{3}(?!-(?!\d)))(?![\dXx])/
    INTERVAL_SEPARATOR = '/'
    HYPHEN_RANGE = /\A(\d{4})\s*-\s*(\d{4})\z/
    LIST_SEPARATOR = /\s*[,;]\s*/
    APPROXIMATE_PREFIX = /\A(?:ca\.?|circa|c\.)\s*/i
    EDTF_SET_BRACKETS = '[]{}'
    EDTF_SET_RUN = /(\d)?\.\.(\d)?/

    def call(*values)
      values.flatten.flat_map { |value| years_in(value) }.uniq.sort
    end

    def years_in(value)
      text = value.to_s.tr(EDTF_SET_BRACKETS, ' ').strip.gsub(EDTF_SET_RUN, '\\1/\\2').sub(APPROXIMATE_PREFIX, '')
      return [] if text.empty?
      return text.split(LIST_SEPARATOR).flat_map { |part| years_in(part) } if text.match?(LIST_SEPARATOR)

      text = text.sub(HYPHEN_RANGE, '\\1/\\2')
      return interval_years(text) if text.include?(INTERVAL_SEPARATOR)

      Array(leading_year(text))
    end

    def interval_years(text)
      years = text.split(INTERVAL_SEPARATOR, -1).filter_map { |part| leading_year(part) }.uniq.sort
      return years if years.length < 2

      (years.first..years.last).take(MAX_INTERVAL_SPAN)
    end

    def leading_year(text)
      text[LEADING_YEAR, 1]&.to_i
    end
  end
end
