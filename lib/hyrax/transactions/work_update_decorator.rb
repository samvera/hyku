# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0 to add custom relations to the change_set

module Hyrax
  module Transactions
    module WorkUpdateDecorator
      default_steps = Hyrax::Transactions::WorkUpdate::DEFAULT_STEPS.dup
      DEFAULT_STEPS = default_steps.insert(default_steps.index('change_set.apply'), 'change_set.add_custom_relations').freeze

      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end

Hyrax::Transactions::WorkUpdate.prepend(Hyrax::Transactions::WorkUpdateDecorator)
