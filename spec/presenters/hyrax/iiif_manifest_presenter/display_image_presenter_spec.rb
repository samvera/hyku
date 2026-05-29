# frozen_string_literal: true

RSpec.describe Hyrax::IiifManifestPresenter::DisplayImagePresenter do
  let(:presenter) { described_class.new(work) }

  let(:work) { double(GenericWork) }

  # verify the native Hyrax AV concern is mixed in
  it "includes Hyrax::DisplaysContent" do
    expect(described_class.include?(Hyrax::DisplaysContent)).to be true
  end
end
