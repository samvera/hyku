require 'spec_helper'

RSpec.describe NilFcrepoEndpoint do
  let(:instance) { described_class.new }

  describe "#ping" do
    subject { instance.ping }

    it { is_expected.to be false }
  end

  describe "#persisted?" do
    it { is_expected.not_to be_persisted }
  end

  describe "#url" do
    subject { instance.url }

    it { is_expected.to eq 'Fcrepo not initialized' }
  end

  describe "#base_path" do
    subject { instance.base_path }

    it { is_expected.to eq 'Fcrepo not initialized' }
  end
end
