# frozen_string_literal: true

RSpec.describe Hyrax::QuickClassificationQuery, type: :decorator do
  subject { described_class.new(user) }

  let(:site) { create(:site, available_works: available_works) }
  let(:user) { create(:user) }
  let(:available_works) { ['GenericWork', 'Image', 'SomeOtherWork'] }

  before do
    allow(Site).to receive(:instance).and_return(site)
    allow(site).to receive(:available_works).and_return(available_works)
  end

  describe '#initialize' do
    context 'when flexible metadata is disabled' do
      before do
        allow(Hyrax.config).to receive(:flexible?).and_return(false)
      end

      it 'uses Site.instance.available_works instead of Hyrax.config.registered_curation_concern_types' do
        expect(subject.instance_variable_get(:@models)).to eq available_works
      end
    end

    context 'when flexible metadata is enabled' do
      let(:profile) { { 'classes' => { 'GenericWorkResource' => {}, 'ImageResource' => {} } } }

      before do
        allow(Hyrax.config).to receive(:flexible?).and_return(true)
        allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(profile)
        allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image', 'Video'])
      end

      it 'filters available works based on both site settings and metadata profile' do
        # Should include only works that are in both available_works and profile
        expect(subject.instance_variable_get(:@models)).to eq(['GenericWork', 'Image'])
      end

      context 'when profile is nil' do
        let(:profile) { nil }

        it 'falls back to using Site.instance.available_works' do
          expect(subject.instance_variable_get(:@models)).to eq available_works
        end
      end
    end
  end

  describe '#all?' do
    context 'when flexible metadata is disabled' do
      before do
        allow(Hyrax.config).to receive(:flexible?).and_return(false)
      end

      it 'uses Site.instance.available_works instead of Hyrax.config.registered_curation_concern_types' do
        expect(subject.all?).to eq true
      end
    end

    context 'when flexible metadata is enabled with profile' do
      let(:profile) { { 'classes' => { 'GenericWorkResource' => {}, 'ImageResource' => {} } } }

      before do
        allow(Hyrax.config).to receive(:flexible?).and_return(true)
        allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(profile)
        allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image'])
      end

      it 'compares against filtered available works' do
        filtered_query = described_class.new(user, models: ['GenericWork', 'Image'])
        expect(filtered_query.all?).to eq true
      end
    end
  end
end
