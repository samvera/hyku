# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NilSolrEndpoint do
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

    it { is_expected.to eq 'Solr not initialized' }
  end

  describe '#switch!' do
    it "does not raise an error" do
      expect(instance).to receive(:connection).at_least(1).times.and_call_original
      expect { instance.switch! }.not_to raise_error
    end
  end
end
