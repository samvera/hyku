# frozen_string_literal: true

module Hyrax
  # View helpers for the guided deposit wizard.
  module DepositWizardHelper
    # These read the deposit-mode config. They are view helpers (not presenter
    # methods) because the legacy entry points — the works-page buttons, a
    # collection's add-items button, the themed homepage share buttons — render
    # outside DepositWizardController and so have no wizard presenter in scope. See
    # the deposit modes in docs/deposit-wizard.md.
    def deposit_wizard_config
      Hyku::DepositWizard.config
    end

    # True when guided deposit is enabled: the standard "Add new work" entry points
    # open the guided wizard instead of the standard form.
    delegate :guided_replaces_standard?, to: :deposit_wizard_config

    # Whether to show the standard-deposit button on the works page (independent of
    # guided; each enable flag adds its own button).
    def show_standard_deposit_button?
      deposit_wizard_config.standard_deposit_button?
    end

    # Whether to show the guided-deposit button on the works page.
    def show_guided_deposit_button?
      deposit_wizard_config.enabled?
    end

    # A deposit entry point's +[href, data]+ — routes into the guided wizard when
    # guided has taken over, otherwise the standard target. Used by the non-works-page
    # entry points (collection add-items, themed homepage share buttons), which flip
    # to guided when it is enabled. Takes primitives (not a presenter) because those
    # views expose +many+ / +first_type+ under different presenter method names.
    def deposit_new_work_target(many:, first_type:)
      return [main_app.deposit_wizard_path, {}] if guided_replaces_standard?

      standard_deposit_target(many: many, first_type: first_type)
    end

    # The standard-deposit +[href, data]+, never routed to guided: the select-work
    # modal when several types are creatable, else a direct link to the only type.
    def standard_deposit_target(many:, first_type:)
      return ['#', { behavior: 'select-work', toggle: 'modal', target: '#worktypes-to-create', 'create-type' => 'single' }] if many

      [new_polymorphic_path([main_app, first_type]), {}]
    end

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
