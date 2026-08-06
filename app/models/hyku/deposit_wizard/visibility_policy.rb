# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Which visibility options the deposit wizard may offer for a given admin set,
    # plus any forced embargo date. This ports Hyrax's client-side
    # VisibilityComponent#applyRestrictions to the server so the wizard renders
    # only the allowed options instead of showing all and disabling some.
    #
    # Built from the admin set's permission-template data (the data-* hash the
    # stock AdminSetSelectionPresenter emits): data-visibility (a required
    # visibility), data-release-no-delay (must release immediately), data-release-
    # date (a release-date requirement), data-release-before-date (whether that
    # date is a ceiling rather than an exact date).
    class VisibilityPolicy
      AR = Hydra::AccessControls::AccessRight
      OPEN = AR::VISIBILITY_TEXT_VALUE_PUBLIC
      AUTHENTICATED = AR::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      EMBARGO = AR::VISIBILITY_TEXT_VALUE_EMBARGO
      LEASE = AR::VISIBILITY_TEXT_VALUE_LEASE
      PRIVATE = AR::VISIBILITY_TEXT_VALUE_PRIVATE
      ALL = [OPEN, AUTHENTICATED, EMBARGO, LEASE, PRIVATE].freeze

      # @param data [Hash] the admin set's data-* hash (string keys as rendered)
      def self.from_admin_set_data(data)
        data = data.to_h.transform_keys { |k| k.to_s.sub(/\Adata-/, '') }
        new(visibility: data['visibility'].presence,
            release_no_delay: truthy?(data['release-no-delay']),
            release_date: data['release-date'].presence,
            release_before: truthy?(data['release-before-date']))
      end

      def self.truthy?(value)
        %w[true 1].include?(value.to_s)
      end

      def initialize(visibility: nil, release_no_delay: false, release_date: nil, release_before: false)
        @visibility = visibility
        @release_no_delay = release_no_delay
        @release_date = release_date
        @release_before = release_before
      end

      # The visibility values allowed under this policy, in display order.
      def allowed_visibilities
        return ALL unless restricted?

        if release_now_required?
          @visibility ? [@visibility] : (ALL - [EMBARGO, LEASE])
        elsif required_embargo?
          [EMBARGO]
        else # release-now-or-embargo
          @visibility ? [@visibility, EMBARGO] : (ALL - [LEASE])
        end
      end

      # A date the embargo must fall on (exact requirement), or nil.
      def forced_embargo_date
        @release_date if required_embargo?
      end

      # The latest allowed embargo release date, or nil for no ceiling.
      def max_embargo_date
        @release_date
      end

      private

      def restricted?
        @visibility.present? || @release_no_delay || @release_date.present?
      end

      def release_now_required?
        @release_no_delay || (@release_date && Time.zone.today > Date.parse(@release_date))
      end

      def required_embargo?
        @release_date.present? && !@release_before && !release_now_required?
      end
    end
  end
end
