# frozen_string_literal: true

RSpec.describe Hyrax::IiifManifestPresenter do
  subject(:presenter) { described_class.new(work) }

  let(:work) { double(GenericWork) }

  it { is_expected.to respond_to(:iiif_version) }

  it 'has Hyku::Ranges in its ancestor chain' do
    expect(described_class.ancestors).to include(Hyku::Ranges)
  end

  it 'has Ranges prepended outermost (before the Hyku decorator)' do
    ranges_idx = described_class.ancestors.index(Hyku::Ranges)
    decorator_idx = described_class.ancestors.index(Hyrax::IiifManifestPresenterDecorator)

    expect(ranges_idx).to be < decorator_idx
  end

  describe Hyrax::IiifManifestPresenter::DisplayImagePresenter do
    it 'includes Hyku::DisplaysItemMetadata' do
      expect(described_class.ancestors).to include(Hyku::DisplaysItemMetadata)
    end
  end
end
