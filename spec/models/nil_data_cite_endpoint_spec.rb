# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NilDataCiteEndpoint do
  let(:instance) { described_class.new }

  describe "#ping" do
    subject { instance.ping }

    it { is_expected.to be false }
  end

  describe "#persisted?" do
    it { is_expected.not_to be_persisted }
  end

  describe "#mode" do
    subject { instance.mode }

    it { is_expected.to eq nil }
  end

  describe "#prefix" do
    subject { instance.prefix }

    it { is_expected.to eq nil }
  end

  describe "#username" do
    subject { instance.username }

    it { is_expected.to eq nil }
  end

  describe "#password" do
    subject { instance.password }

    it { is_expected.to eq nil }
  end
end
