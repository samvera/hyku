# frozen_string_literal: true

module Hyku
  module DepositWizard
    # The wizard's step sequence as data. A Flow is an ordered list of Steps plus a
    # navigator (next/back/detour/rail) computed from each Step's declared rules,
    # so ordering, skips, prerequisites, and the stepper rail live in one place
    # instead of scattered across the presenter and views. A downstream app
    # reshapes the wizard by building a new step list (from Flow.default_steps) and
    # assigning config.flow, rather than editing flow logic.
    #
    # Each Step declares:
    # - +name+       the step key (matches the view template + :step route param).
    # - +requires+   named state prerequisites (see Flow::PREREQUISITES). A step
    #                whose prerequisite is unmet is detoured to the step that
    #                fulfills it. Only +:work_type+ exists today; the admin set is
    #                auto-resolved (never blocking) so it is NOT a prerequisite.
    # - +skip_if+    ->(state, config) — when true the step is not visible (skipped
    #                by next/back, detoured away from if requested directly).
    # - +terminal+   true for a step reached by a non-advance action (review→commit
    #                →done); terminal steps are never an advance target.
    # - +on_skip+    where a direct visit lands when the step is skipped: +:forward+
    #                (default — a transparent pass-through, e.g. item_start with no
    #                sub-flow → next step) or +:entry+ (an invalid entry, e.g.
    #                select_parent when not on the add path → back to the start).
    # - rail metadata: +rail_key+ (steps sharing a key collapse to one rail entry),
    #                +rail_if+ ->(state, config) whether the entry shows, +icon+,
    #                +label_key+ (i18n suffix under hyku.deposit_wizard.stepper.item).
    class Flow
      Step = Struct.new(
        :name, :requires, :skip_if, :terminal, :on_skip,
        :rail_key, :rail_if, :icon, :label_key,
        keyword_init: true
      ) do
        def visible?(state, config)
          skip_if.nil? || !skip_if.call(state, config)
        end

        def rail_visible?(state, config)
          rail_key.present? && (rail_if.nil? || rail_if.call(state, config))
        end
      end

      # Named prerequisites a Step can require. +step+ is where the navigator
      # detours when the prerequisite is unmet.
      PREREQUISITES = {
        work_type: { met: ->(state, _config) { state.work_type.present? }, step: 'known_type' }
      }.freeze

      # The stepper rail's display order, as phase keys. Deliberately its OWN
      # ordered list rather than derived from the step sequence: several steps
      # collapse into one rail phase (start/item_start/known_type all → :type), and
      # a downstream app may want the phases in a different order than the steps are
      # walked. A phase shows only when a visible step maps to it (see #rail).
      DEFAULT_RAIL_KEYS = %i[parent type upload detail file_detail review].freeze

      attr_reader :steps, :rail_keys

      def initialize(steps, rail_keys: DEFAULT_RAIL_KEYS)
        @steps = steps
        @rail_keys = rail_keys
      end

      def self.default
        new(default_steps)
      end

      # Mirrors the pre-Flow step behavior exactly (the parity contract).
      def self.default_steps # rubocop:disable Metrics/MethodLength
        [
          Step.new(name: 'start', rail_key: :type, icon: 'fa-list-alt', label_key: 'type'),
          Step.new(name: 'select_parent',
                   skip_if: ->(state, _c) { state.path != 'add' }, on_skip: :entry,
                   rail_key: :parent, rail_if: ->(state, _c) { state.path == 'add' },
                   icon: 'fa-sitemap', label_key: 'parent'),
          Step.new(name: 'item_start',
                   skip_if: ->(_s, config) { !config.item_start_offers_choice? },
                   rail_key: :type),
          Step.new(name: 'known_type', rail_key: :type),
          Step.new(name: 'files', rail_key: :upload, icon: 'fa-cloud-upload', label_key: 'upload'),
          Step.new(name: 'details', requires: %i[work_type],
                   rail_key: :detail, icon: 'fa-pencil', label_key: 'detail'),
          Step.new(name: 'file_meta', requires: %i[work_type],
                   skip_if: ->(state, _c) { state.uploaded_file_ids.empty? },
                   rail_key: :file_detail, rail_if: ->(state, _c) { state.uploaded_file_ids.any? },
                   icon: 'fa-file-text-o', label_key: 'file_detail'),
          Step.new(name: 'review', requires: %i[work_type],
                   rail_key: :review, icon: 'fa-check', label_key: 'review'),
          Step.new(name: 'done', terminal: true)
        ]
      end

      def names
        steps.map(&:name)
      end

      def valid_step?(name)
        names.include?(name.to_s)
      end

      def step(name)
        steps.find { |s| s.name == name.to_s }
      end

      # Renderable steps for the current state: non-terminal and not skipped.
      def visible_steps(state, config)
        steps.reject(&:terminal).select { |s| s.visible?(state, config) }
      end

      # The next visible, non-terminal step after +name+, or nil at the end. Uses
      # the FULL step order to locate +name+ (so a skipped step still has a
      # position) then scans forward for the next visible step.
      def next_after(name, state, config)
        after = steps.drop_while { |s| s.name != name.to_s }.drop(1)
        after.find { |s| !s.terminal && s.visible?(state, config) }&.name
      end

      # The previous visible step before +name+, or nil at the entry (the root).
      def back_before(name, state, config)
        before = steps.take_while { |s| s.name != name.to_s }
        before.reverse.find { |s| !s.terminal && s.visible?(state, config) }&.name
      end

      # Where a requested step should redirect instead of rendering, or nil to
      # render it: to the step fulfilling an unmet prerequisite, or (if the step is
      # skipped in the current state) on to its next visible step / the entry.
      def detour_for(name, state, config)
        step = step(name)
        return nil if step.nil?

        Array(step.requires).each do |req|
          rule = PREREQUISITES[req]
          return rule[:step] if rule && !rule[:met].call(state, config)
        end

        return nil if step.visible?(state, config)

        # A skipped step: :entry sends an invalid direct visit back to the start;
        # otherwise pass through to the next visible step.
        return names.first if step.on_skip == :entry

        next_after(name, state, config) || back_before(name, state, config) || names.first
      end

      # The stepper rail, in +rail_keys+ order. A phase appears only when a visible
      # step maps to it (so :parent shows on the add path, :file_detail with files).
      # Order is the rail_keys list, NOT the step sequence, so display order and flow
      # order stay independent. A phase's icon/label come from whichever visible step
      # in the group defines them, since collapsed steps (start/item_start/known_type
      # → :type) don't all carry them.
      def rail(state, config)
        rail_keys.filter_map do |key|
          group = visible_steps(state, config).select { |s| s.rail_key == key && s.rail_visible?(state, config) }
          next if group.empty?

          { key: key,
            icon: group.filter_map(&:icon).first,
            label_key: group.filter_map(&:label_key).first }
        end
      end
    end
  end
end
