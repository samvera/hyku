# frozen_string_literal: true

module Hyrax
  # View helpers for the guided deposit wizard.
  module DepositWizardHelper
    # Render a human-readable visibility summary for the review step. For open and
    # restricted, this is just the visibility badge. For embargo and lease, the
    # base "visibility" is the transitional state (e.g. "embargo"), so a badge
    # alone reads as meaningless: show the during/after visibilities and the date
    # instead ("Embargo: private until 2026-08-01, then open").
    #
    # @param attributes [Hash] string-keyed visibility attributes (visibility plus
    #   any embargo/lease during/after/date fields), as collected by the wizard.
    def visibility_summary(attributes)
      attrs = attributes.to_h.stringify_keys
      case attrs['visibility']
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
        embargo_lease_summary('embargo', attrs['visibility_during_embargo'],
                              attrs['visibility_after_embargo'], attrs['embargo_release_date'])
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
        embargo_lease_summary('lease', attrs['visibility_during_lease'],
                              attrs['visibility_after_lease'], attrs['lease_expiration_date'])
      when nil, ''
        t('hyku.deposit_wizard.review.visibility_inherited')
      else
        visibility_badge(attrs['visibility'])
      end
    end

    private

    def embargo_lease_summary(kind, during, after, date)
      t("hyku.deposit_wizard.review.#{kind}_summary_html",
        during: visibility_badge(during),
        after: visibility_badge(after),
        date: format_release_date(date))
    end

    # Accepts a Date/Time/DateTime or a string (per-file params arrive as strings,
    # work sub-forms as DateTime) and renders a plain YYYY-MM-DD date. A string that
    # is not a parseable date is returned as-is (escaped by the caller).
    def format_release_date(date)
      return '' if date.blank?

      date.to_date.iso8601
    rescue ArgumentError
      date.to_s
    end
  end
end
