# frozen_string_literal: true

RSpec.describe MediaViewerFormBehavior do
  subject(:form) { GenericWorkResourceForm.new(GenericWorkResource.new) }

  let!(:test_strategy) { Flipflop::FeatureSet.current.test! }
  let(:feature_default) { Flipflop::FeatureSet.current.feature(:per_work_media_viewer).default }

  after { test_strategy.switch!(:per_work_media_viewer, feature_default) }

  context 'when the feature is disabled' do
    before { test_strategy.switch!(:per_work_media_viewer, false) }

    it 'keeps the viewer picker off the form, where a choice would be ignored' do
      expect(form.secondary_terms).not_to include(:media_viewer)
      expect(form.primary_terms).not_to include(:media_viewer)
    end

    it 'leaves the other fields alone' do
      expect(form.secondary_terms).to include(:video_embed)
    end
  end

  context 'when the feature is enabled' do
    before { test_strategy.switch!(:per_work_media_viewer, true) }

    it 'offers the viewer picker' do
      skip 'flexible mode takes the field from the profile, not the static schema' if Hyrax.config.flexible?

      expect(form.secondary_terms).to include(:media_viewer)
    end
  end
end
