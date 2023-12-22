# frozen_string_literal: true

RSpec.describe Hyrax::QuickClassificationQuery, type: :decorator do
  subject { described_class.new(user) }

  let(:site) { create(:site, available_works:) }
  let(:user) { create(:user) }
  let(:available_works) { ['GenericWork', 'Image', 'SomeOtherWork'] }

  before do
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
end
