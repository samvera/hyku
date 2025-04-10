# frozen_string_literal: true

# OVERRIDE Hyrax v2.9.0
RSpec.describe Hyrax::QuickClassificationQuery, clean_repo: true do
  # Ensure Hyrax::ModelRegistry.work_classes is loaded so this spec doesn't leak into other specs
  let!(:work_classes) { Hyrax::ModelRegistry.work_classes }
  # OVERRIDE: add :work_depositor role -- proper testing requires create permission
  let(:user) { create(:user, roles: [:work_depositor]) }

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
