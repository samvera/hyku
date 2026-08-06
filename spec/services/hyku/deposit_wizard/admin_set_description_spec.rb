# frozen_string_literal: true

RSpec.describe Hyku::DepositWizard::AdminSetDescription do
  subject(:builder) { described_class.new(admin_set: admin_set, permission_template: template) }

  let(:admin_set) { double(description: description) }
  let(:template) { double(active_workflow: workflow) }
  let(:workflow) { double(label: 'Manager approval') }
  let(:description) { ['For sensitive works — no public access.'] }

  describe '#summary' do
    it 'returns the admin set description' do
      expect(builder.summary).to eq('For sensitive works — no public access.')
    end

    context 'when the description is blank' do
      let(:description) { [''] }

      it 'is nil' do
        expect(builder.summary).to be_nil
      end
    end
  end

  describe '#workflow_label' do
    it 'returns the active workflow label' do
      expect(builder.workflow_label).to eq('Manager approval')
    end

    context 'without an active workflow' do
      let(:template) { double(active_workflow: nil) }

      it 'is nil' do
        expect(builder.workflow_label).to be_nil
      end
    end

    context 'without a permission template' do
      let(:template) { nil }

      it 'is nil' do
        expect(builder.workflow_label).to be_nil
      end
    end
  end
end
