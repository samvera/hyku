# frozen_string_literal: true

require 'rubocop'

module Hyrax
  module RuboCop
    module CustomCops
      # This custom cop checks for proper OVERRIDE comment formatting
      class OverrideComment < ::RuboCop::Cop::Cop
        MSG = 'OVERRIDE comment must follow format: `# OVERRIDE class from <library name> <library version> <reason>` with reason being optional.'

        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless override_comment?(comment)

            check_override_format(comment)
          end
        end

        private

        def override_comment?(comment)
          comment.text.match?(/^\s*#\s*OVERRIDE\b/i)
        end

        def check_override_format(comment)
          text = comment.text.strip

          # Check if it matches the required pattern
          # Pattern: # OVERRIDE class from <library name> <library version> [reason]
          pattern = /^\s*#\s*OVERRIDE\s+class\s+from\s+\S+\s+\S+(?:\s+.*)?$/i

          return if text.match?(pattern)
          add_offense(comment, message: MSG)
        end
      end

      # class AdditionalCustomCops < ::RuboCop::Cop::Cop; end
    end
  end
end
