# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0 to add custom relations to the change_set

module Hyrax
  module Transactions
    module WorkCreateDecorator
      default_steps = Hyrax::Transactions::WorkCreate::DEFAULT_STEPS.dup
      DEFAULT_STEPS = default_steps.insert(default_steps.index('change_set.apply'), 'change_set.add_custom_relations').freeze

      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end

Hyrax::Transactions::WorkCreate.prepend(Hyrax::Transactions::WorkCreateDecorator)
