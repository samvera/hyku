# frozen_string_literal: true

module Hyku
  module DepositWizard
    # The derived state the visibility partial renders: the currently-selected
    # option plus the embargo/lease values to prefill (so navigating Back restores
    # them). Built by Presenter#visibility_fields; the partial owns only labels,
    # notes, and markup.
    VisibilityFields = Struct.new(
      :current,
      :embargo_date, :embargo_during, :embargo_after,
      :lease_date, :lease_during, :lease_after,
      keyword_init: true
    )
  end
end
