# frozen_string_literal: true

RSpec.describe Hyrax::QuickClassificationQuery, type: :decorator do
  subject { described_class.new(user) }

  let(:site) { create(:site, available_works:) }
  let(:user) { create(:user) }
  let(:available_works) { ['GenericWork', 'Image', 'SomeOtherWork'] }

  before do
    allow(Site).to receive(:instance).and_return(site)
    allow(site).to receive(:available_works).and_return(available_works)
  end

  describe '#initialize' do
    it 'uses Site.instance.available_works instead of Hyrax.config.registered_curation_concern_types' do
      expect(subject.instance_variable_get(:@models)).to eq available_works
    end
  end

  describe '#all?' do
    it 'uses Site.instance.available_works instead of Hyrax.config.registered_curation_concern_types' do
      expect(subject.all?).to eq true
    end
  end

  describe '#filtered_available_works' do
    context 'when HYRAX_FLEXIBLE is false' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

      it 'returns Site.instance.available_works' do
        expect(subject.send(:filtered_available_works)).to eq available_works
      end
    end

    context 'when HYRAX_FLEXIBLE is true' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(true) }

      context 'with a search-only tenant' do
        let(:full_account) { create(:account, search_only: false) }
        let(:search_only_account) do
          create(:account, search_only: true, full_account_cross_searches_attributes: [
                   { full_account_id: full_account.id }
                 ])
        end

        before do
          allow(Site).to receive(:account).and_return(search_only_account)
        end

        it 'returns Site.instance.available_works without trying to access flexible schema' do
          # Should not call Hyrax::FlexibleSchema.current_version for search-only tenants
          expect(Hyrax::FlexibleSchema).not_to receive(:current_version)
          expect(subject.send(:filtered_available_works)).to eq available_works
        end
      end

      context 'with a regular tenant' do
        let(:account) { create(:account, search_only: false) }
        let(:mock_profile) do
          {
            'classes' => {
              'GenericWorkResource' => {},
              'ImageResource' => {}
            }
          }
        end

        before do
          allow(Site).to receive(:account).and_return(account)
          allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(mock_profile)
          allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image', 'Etd'])
        end

        it 'filters available works based on flexible metadata profile' do
          # Should return intersection of available_works and profile work types
          expect(subject.send(:filtered_available_works)).to eq ['GenericWork', 'Image']
        end
      end

      context 'when flexible schema current_version returns nil' do
        let(:account) { create(:account, search_only: false) }

        before do
          allow(Site).to receive(:account).and_return(account)
          allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(nil)
        end

        it 'returns Site.instance.available_works' do
          expect(subject.send(:filtered_available_works)).to eq available_works
        end
      end
    end
  end
end
