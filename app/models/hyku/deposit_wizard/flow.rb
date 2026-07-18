# frozen_string_literal: true

module Hyku
  module DepositWizard
    # The wizard's step sequence as data, built on the generic FlowWizard engine.
    # A Flow is an ordered list of Steps plus a navigator (next/back/detour/rail)
    # computed from each Step's declared rules, so ordering, skips, prerequisites,
    # and the stepper rail live in one place. A downstream app reshapes the wizard
    # by building a new step list (from Flow.default_steps) and assigning config.flow.
    #
    # The default flow is expressed with the FlowWizard builder using NAMED
    # conditions (`adding`, `has_files`, the `work_type` prerequisite) rather than
    # inline lambdas, so the same predicate is stated once and the flow renders to a
    # self-documenting diagram (see Flow#to_mermaid / `rake deposit_wizard:diagram`).
    class Flow < FlowWizard::Flow
      # Keep Flow::Step as the documented public constant (the builder produces
      # these under the hood; downstream code and specs reference Flow::Step).
      Step = FlowWizard::Step

      # The stepper rail's display order, as phase keys — its OWN ordered list, since
      # several steps collapse into one phase (start/item_start/known_type → :type)
      # and the display order may differ from the walk order.
      DEFAULT_RAIL_KEYS = %i[parent type upload detail file_detail review].freeze

      # The built-in flow. Downstream apps assign their own via config.flow.
      def self.default
        build_default
      end

      # The default step list (for callers that reshape it, e.g.
      # `Flow.new(default_steps + [extra_step])`). Returns FlowWizard::Steps.
      def self.default_steps
        build_default.steps
      end

      # The named-condition registry the default flow uses (exposed so a reshaped
      # flow built from default_steps can pass the same conditions through).
      def self.default_conditions
        build_default.conditions
      end

      # Builds the default flow once (memoized): the parity contract with the
      # pre-FlowWizard behavior, now expressed via the builder.
      def self.build_default
        @build_default ||= FlowWizard::Flow.build do
          rail_order(*DEFAULT_RAIL_KEYS)

          condition :adding,    ->(state, _c) { state.path == 'add' }
          condition :has_files, ->(state, _c) { state.uploaded_file_ids.any? }
          # item_start only offers a choice when a guided sub-flow is configured.
          condition :guided_offered, ->(_s, config) { config.item_start_offers_choice? }
          prerequisite :work_type, ->(state, _c) { state.work_type.present? }, detour: :known_type

          step :start, rail: :type, icon: 'fa-list-alt', label_key: 'type'
          step :select_parent, skip_unless: :adding, on_skip: :entry,
                               rail: :parent, rail_if: :adding, icon: 'fa-sitemap', label_key: 'parent'
          step :item_start, skip_unless: :guided_offered, rail: :type
          step :known_type, rail: :type
          step :files, rail: :upload, icon: 'fa-cloud-upload', label_key: 'upload'
          step :details, requires: :work_type, rail: :detail, icon: 'fa-pencil', label_key: 'detail'
          step :file_meta, requires: :work_type, skip_unless: :has_files,
                           rail: :file_detail, rail_if: :has_files, icon: 'fa-file-text-o', label_key: 'file_detail'
          step :review, requires: :work_type, rail: :review, icon: 'fa-check', label_key: 'review'
          step :done, terminal: true
        end
      end

      # Preserve the (steps, rail_keys:) constructor for callers that build a Flow
      # from default_steps; forward to the engine, threading the default conditions
      # so named conditions on those steps still resolve.
      def initialize(steps, rail_keys: DEFAULT_RAIL_KEYS, conditions: self.class.default_conditions)
        super(steps, rail_keys: rail_keys, conditions: conditions)
      end
    end
  end
end
