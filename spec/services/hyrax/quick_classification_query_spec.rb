# frozen_string_literal: true

# OVERRIDE FILE from Hyrax v2.9.0
RSpec.describe Hyrax::QuickClassificationQuery do
  let(:user) { create(:user) }

  context "with no options" do
    let(:query) { described_class.new(user) }

    describe "#all?" do
      subject { query.all? }

      it { is_expected.to be true }
    end

    describe '#each' do
      let(:thing) { double }

      before do
        # Ensure that no other test has altered the configuration:
        allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork'])
      end
      it "calls the block once for every model" do
        expect(thing).to receive(:test).with(GenericWork)
        query.each do |f|
          thing.test(f)
        end
      end
    end
  end

  context "with models" do
    let(:query) { described_class.new(user, models: ['dataset']) }

    describe "#all?" do
      subject { query.all? }

      it { is_expected.to be false }
    end
  end

  ####################################################################################################
  # OVERRIDE: newly added specs below (Hyku-specific)
  ####################################################################################################

  context 'when a work type has been disabled in a tenant' do
    let(:query) { described_class.new(user) }

    before do
      allow(Hyrax.config).to receive(:registered_curation_concern_types).and_return(['GenericWork', 'Image'])
      # Simulate Image work type being disabled within the tenant
      Site.instance.update(available_works: ['GenericWork'])
    end

    it 'only queries enabled work types' do
      expect(user).to receive(:can?).with(:create, GenericWork)
      expect(user).not_to receive(:can?).with(:create, Image)

      query.authorized_models
    end
  end
end
