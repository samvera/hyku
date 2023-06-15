# frozen_string_literal: true

RSpec.describe Hyrax::IiifManifestPresenter::DisplayImagePresenter do
  let(:presenter) { described_class.new(work) }

  let(:work) { double(GenericWork) }

  # verify that the decorator is being loaded
  it "includes Hyrax::IiifAv::DisplaysContent" do
    expect(described_class.include?(Hyrax::IiifAv::DisplaysContent)).to be true
  end
end
