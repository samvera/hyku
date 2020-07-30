# frozen_string_literal: true

RSpec.describe NilSite do
  let(:instance) { described_class.instance }

  describe "#instance" do
    subject { described_class.instance }

    # 'instance' should always return same obj (i.e. singleton)
    it { is_expected.to be instance }
  end

  describe "#id" do
    subject { instance.id }

    it { is_expected.to be nil }
  end

  describe "#account" do
    subject { instance.account }

    it { is_expected.to be nil }
  end

  describe "#application_name" do
    subject { instance.application_name }

    it { is_expected.to be nil }
  end

  describe "#institution_name" do
    subject { instance.institution_name }

    it { is_expected.to be nil }
  end

  describe "#institution_name_full" do
    subject { instance.institution_name_full }

    it { is_expected.to be nil }
  end

  describe "#reload" do
    subject { instance.reload }

    it { is_expected.to be described_class.instance }
  end

  describe "#update" do
    subject { instance.update(param: 'one') }

    it { is_expected.to be false }
  end

  describe "#admin_emails" do
    context "default value" do
      subject { instance.admin_emails }

      it { is_expected.to be_empty }
    end

    context "set a value" do
      subject { instance.admin_emails }

      before { instance.admin_emails = "test@test.org" }

      it { is_expected.to be_empty }
    end
  end

  describe "#admin_emails=" do
    subject { instance.admin_emails = "one@two.org" }

    it { is_expected.to eq("one@two.org") }
  end

  describe "#banner_image?" do
    subject { instance.banner_image? }

    it { is_expected.to be false }
  end

  describe "#banner_image" do
    subject { instance.banner_image }

    it { is_expected.to be nil }
  end

  describe "#directory_image?" do
    subject { instance.directory_image? }

    it { is_expected.to be false }
  end

  describe "#directory_image" do
    subject { instance.directory_image }

    it { is_expected.to be nil }
  end

  describe "#primary_key" do
    subject { instance.primary_key }

    it { is_expected.to be nil }
  end
end
