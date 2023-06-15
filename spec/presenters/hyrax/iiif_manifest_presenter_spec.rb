# frozen_string_literal: true

RSpec.describe Hyrax::IiifManifestPresenter do
  subject(:presenter) { described_class.new(work) }

  let(:work) { double(GenericWork) }

  # verify that the decorator is being loaded
  it { is_expected.to respond_to(:iiif_version) }
end
