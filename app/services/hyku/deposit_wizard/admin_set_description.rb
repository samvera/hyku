# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Builds the human-facing guidance shown for one admin set on the deposit
    # wizard's start step: the workflow label (badge) and a one-line summary that
    # tells the depositor what choosing this set means.
    #
    # Isolated from the presenter because deriving readable guidance from an admin
    # set is fiddly and is expected to grow (composing visibility and release rules
    # into prose). For now the summary is the set's own description; #summary is
    # the single seam to enrich later.
    class AdminSetDescription
      # @param admin_set [#description] the admin set document
      # @param permission_template [Hyrax::PermissionTemplate, nil] its template,
      #   used for the active-workflow label
      def initialize(admin_set:, permission_template: nil)
        @admin_set = admin_set
        @permission_template = permission_template
      end

      # The curator-authored one-liner shown under the selector, or nil when the
      # set has no description.
      def summary
        Array(@admin_set.try(:description)).first.presence
      end

      # The active workflow's label for the badge (e.g. "Manager approval"), or nil
      # when the set has no active workflow.
      def workflow_label
        @permission_template&.active_workflow&.label.presence
      end
    end
  end
end
