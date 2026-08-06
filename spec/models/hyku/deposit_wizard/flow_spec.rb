# frozen_string_literal: true

RSpec.describe Hyku::DepositWizard::Flow do
  subject(:flow) { described_class.default }

  let(:config) { Hyku::DepositWizard::Config.new }
  let(:state) { Hyku::DepositWizard::State.new({}) }

  describe 'the default sequence' do
    it 'mirrors the wizard step order' do
      expect(flow.names).to eq(%w[start select_parent item_start known_type files details file_meta review done])
    end

    it 'validates step names' do
      expect(flow).to be_valid_step('review')
      expect(flow).not_to be_valid_step('bogus')
    end
  end

  describe 'visibility / skips' do
    it 'hides select_parent unless the add path is active' do
      expect(flow.visible_steps(state, config).map(&:name)).not_to include('select_parent')
      state.path = 'add'
      expect(flow.visible_steps(state, config).map(&:name)).to include('select_parent')
    end

    it 'hides item_start unless a guided sub-flow is configured' do
      expect(flow.visible_steps(state, config).map(&:name)).not_to include('item_start')
      config.suggestions = { image: %w[artefact] }
      expect(flow.visible_steps(state, config).map(&:name)).to include('item_start')
    end

    it 'hides file_meta unless files were uploaded' do
      expect(flow.visible_steps(state, config).map(&:name)).not_to include('file_meta')
      state.uploaded_file_ids = ['abc']
      expect(flow.visible_steps(state, config).map(&:name)).to include('file_meta')
    end
  end

  describe '#next_after' do
    it 'skips over hidden steps (known_type -> files with no sub-flow)' do
      expect(flow.next_after('known_type', state, config)).to eq('files')
    end

    it 'skips file_meta straight to review when there are no files' do
      expect(flow.next_after('details', state, config)).to eq('review')
    end

    it 'includes file_meta when files were uploaded' do
      state.uploaded_file_ids = ['abc']
      expect(flow.next_after('details', state, config)).to eq('file_meta')
    end

    it 'routes start to select_parent on the add path' do
      state.path = 'add'
      expect(flow.next_after('start', state, config)).to eq('select_parent')
    end
  end

  describe '#back_before' do
    it 'matches the prior visible step for each step (mirrors the old literals)' do
      state.uploaded_file_ids = ['abc'] # so file_meta is visible
      state.work_type = 'GenericWork'
      expect(flow.back_before('files', state, config)).to eq('known_type')
      expect(flow.back_before('details', state, config)).to eq('files')
      expect(flow.back_before('file_meta', state, config)).to eq('details')
      expect(flow.back_before('review', state, config)).to eq('file_meta')
    end

    it 'sends review back to details when there are no files' do
      expect(flow.back_before('review', state, config)).to eq('details')
    end

    it 'has no back before the entry step' do
      expect(flow.back_before('start', state, config)).to be_nil
    end
  end

  describe '#detour_for' do
    it 'sends a work-type-requiring step to known_type when no type is chosen' do
      expect(flow.detour_for('details', state, config)).to eq('known_type')
    end

    it 'renders a work-type step once a type is chosen (no detour)' do
      state.work_type = 'GenericWork'
      expect(flow.detour_for('details', state, config)).to be_nil
    end

    it 'skips a transparent hidden step forward (item_start -> known_type)' do
      state.work_type = 'GenericWork'
      expect(flow.detour_for('item_start', state, config)).to eq('known_type')
    end

    it 'bounces an invalid select_parent visit back to the entry' do
      state.work_type = 'GenericWork'
      expect(flow.detour_for('select_parent', state, config)).to eq('start')
    end

    it 'does NOT require a work type for the files step (upload-before-type)' do
      expect(flow.detour_for('files', state, config)).to be_nil
    end
  end

  describe '#rail' do
    it 'collapses start/item_start/known_type into one :type entry' do
      keys = flow.rail(state, config).map { |r| r[:key] }
      expect(keys).to eq(%i[type upload detail review])
    end

    it 'defaults to parent before type on the add path' do
      state.path = 'add'
      state.uploaded_file_ids = ['abc']
      keys = flow.rail(state, config).map { |r| r[:key] }
      expect(keys).to eq(%i[parent type upload detail file_detail review])
    end

    it 'follows a configured rail order independent of the step sequence' do
      reordered = described_class.new(described_class.default_steps,
                                      rail_keys: %i[type parent upload detail file_detail review])
      state.path = 'add'
      keys = reordered.rail(state, config).map { |r| r[:key] }
      expect(keys.first(2)).to eq(%i[type parent])
    end

    it 'sources a phase icon/label from whichever group step defines them, not just the first' do
      # A downstream flow where the first visible step of a rail_key group carries
      # no icon/label but a later one does. The rail row must still get the icon and
      # label from the step that defines them, not nil from the first step.
      step = described_class::Step
      flow = described_class.new(
        [
          step.new(name: 'a', rail_key: :type),
          step.new(name: 'b', rail_key: :type, icon: 'fa-list-alt', label_key: 'type'),
          step.new(name: 'review', rail_key: :review, icon: 'fa-check', label_key: 'review')
        ],
        rail_keys: %i[type review]
      )

      type_row = flow.rail(state, config).find { |r| r[:key] == :type }
      expect(type_row[:icon]).to eq('fa-list-alt')
      expect(type_row[:label_key]).to eq('type')
    end
  end

  describe 'Step constant' do
    it 'is exposed as Flow::Step (the documented public path)' do
      expect(described_class::Step).to be < Struct
    end
  end

  describe 'resequencing seam (files before type)' do
    it 'permits a valid files-first ordering under the prerequisite model' do
      # A downstream flow that puts files before a type-predicting step: because
      # `files` has no work_type prerequisite, reaching it first is legal, and the
      # metadata steps still detour until a type is set.
      step = described_class::Step
      guided = described_class.new(
        [
          step.new(name: 'files'),
          step.new(name: 'guided_confirm'),
          step.new(name: 'details', requires: %i[work_type]),
          step.new(name: 'done', terminal: true)
        ]
      )

      expect(guided.detour_for('files', state, config)).to be_nil
      expect(guided.next_after('files', state, config)).to eq('guided_confirm')
      expect(guided.detour_for('details', state, config)).to eq('known_type')

      state.work_type = 'GenericWork'
      expect(guided.detour_for('details', state, config)).to be_nil
    end
  end
end
