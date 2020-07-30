# frozen_string_literal: true

require 'importer'

RSpec.describe Importer::Factory::StringLiteralProcessor do
  subject { described_class.process(input) }

  let(:input) do
    { title: ["Stanford residences"],
      contributor: [{ name: name, type: "corporate" }] }
  end

  context "with a single name" do
    let(:name) { ["Muybridge"] }

    it do
      expect(subject).to eq(title: ["Stanford residences"],
                            contributor: ['Muybridge'])
    end
  end

  context "with multiple name parts" do
    let(:name) { ["Stanford University", "Archives."] }

    it do
      expect(subject).to eq(title: ["Stanford residences"],
                            contributor: ['Stanford University — Archives.'])
    end
  end

  context "without a contributor" do
    let(:input) do
      { title: ["Stanford residences"] }
    end

    it { expect(subject).to eq(title: ["Stanford residences"]) }
  end
end
