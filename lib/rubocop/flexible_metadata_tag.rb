# frozen_string_literal: true

require 'rubocop'

module Hyrax
  module RuboCop
    module CustomCops
      # Requires every top-level example group in a spec file to say which metadata mode it runs in:
      # `flexible: true`, `flexible: false` or `flexible: :either`. CI splits the suite by this tag
      # (see bin/ci_rspec), and spec/rails_helper.rb skips the groups that don't apply to the current
      # mode. An inner group or example may override the file's tag.
      #
      # @example
      #   # bad
      #   RSpec.describe 'Work show page', type: :feature do
      #
      #   # good
      #   RSpec.describe 'Work show page', type: :feature, flexible: :either do
      #
      # Autocorrect adds `flexible: :either` to a group that has no `flexible:` tag; change it to `true` or
      # `false` when the group only works in one mode.
      class FlexibleMetadataTag < ::RuboCop::Cop::Base
        extend ::RuboCop::Cop::AutoCorrector

        MSG = 'Tag the top-level example group with `flexible: true`, `flexible: false` or `flexible: :either`.'
        GROUP_METHODS = %i[describe context feature xdescribe xcontext xfeature fdescribe fcontext ffeature].freeze

        def on_send(node)
          return unless top_level_group?(node)
          return if valid_tag?(node)

          add_offense(node) do |corrector|
            next if flexible_pair(node) # an invalid value needs a person to choose

            last_argument = node.last_argument
            if last_argument
              corrector.insert_after(last_argument, ', flexible: :either')
            else
              corrector.insert_after(node.loc.selector, ' flexible: :either')
            end
          end
        end

        private

        def top_level_group?(node)
          return false unless GROUP_METHODS.include?(node.method_name)
          return false unless node.receiver.nil? || node.receiver.const_name == 'RSpec'

          block = node.parent
          return false unless block&.block_type? && block.send_node.equal?(node)

          block.each_ancestor(:block).none?
        end

        def flexible_pair(node)
          metadata = node.arguments.reverse.find(&:hash_type?)
          metadata&.pairs&.find { |pair| pair.key.sym_type? && pair.key.value == :flexible }
        end

        def valid_tag?(node)
          pair = flexible_pair(node)
          return false unless pair

          value = pair.value
          value.true_type? || value.false_type? || (value.sym_type? && value.value == :either)
        end
      end
    end
  end
end
