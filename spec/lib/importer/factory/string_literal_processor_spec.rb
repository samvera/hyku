require 'importer'

RSpec.describe Importer::Factory::StringLiteralProcessor do
  let(:input) do
    { title: ["Stanford residences"],
      contributor: [{ name: name, type: "corporate" }] }
  end

  subject { described_class.process(input) }

  context "with a single name" do
    let(:name) { ["Muybridge"] }

    it do
      is_expected.to eq(title: ["Stanford residences"],
                        contributor: ['Muybridge'])
    end
  end

  context "with multiple name parts" do
    let(:name) { ["Stanford University", "Archives."] }

    it do
      is_expected.to eq(title: ["Stanford residences"],
                        contributor: ['Stanford University — Archives.'])
    end
  end

  context "without a contributor" do
    let(:input) do
      { title: ["Stanford residences"] }
    end

    it { is_expected.to eq(title: ["Stanford residences"]) }
  end
end
