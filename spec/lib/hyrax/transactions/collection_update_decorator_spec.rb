# frozen_string_literal: true

RSpec.describe Hyrax::Transactions::CollectionUpdateDecorator do
  let(:decorated_steps) { Hyrax::Transactions::CollectionUpdate.new.steps }

  describe 'DEFAULT_STEPS' do
    it 'includes save_collection_thumbnail after save_collection_logo' do
      steps = described_class::DEFAULT_STEPS
      logo_index = steps.index('collection_resource.save_collection_logo')
      thumb_index = steps.index('collection_resource.save_collection_thumbnail')

      expect(logo_index).to be_present
      expect(thumb_index).to be_present
      expect(thumb_index).to eq(logo_index + 1)
    end

    it 'preserves upstream sync_redirect_paths step' do
      steps = described_class::DEFAULT_STEPS
      expect(steps).to include('collection_resource.sync_redirect_paths')
    end

    it 'preserves upstream save_acl step' do
      steps = described_class::DEFAULT_STEPS
      expect(steps).to include('collection_resource.save_acl')
    end

    it 'is frozen' do
      expect(described_class::DEFAULT_STEPS).to be_frozen
    end
  end

  describe 'step ordering' do
    it 'runs change_set.apply first' do
      expect(described_class::DEFAULT_STEPS.first).to eq('change_set.apply')
    end

    it 'runs sync_redirect_paths last' do
      expect(described_class::DEFAULT_STEPS.last).to eq('collection_resource.sync_redirect_paths')
    end
  end
end
