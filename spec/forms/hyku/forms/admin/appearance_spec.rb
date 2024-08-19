# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyku::Forms::Admin::Appearance do
  let(:instance) { described_class.new }
  describe '.default_fonts' do
    subject { described_class.default_fonts }

    it { is_expected.to be_a(Hash) }

    it "has the 'body_font' and 'headline_font' keys" do
      expect(subject.keys).to match_array(['body_font', 'headline_font'])
    end
  end

  describe '.default_colors' do
    subject { described_class.default_colors }

    it { is_expected.to be_a(Hash) }
  end

  describe '.image_params' do
    subject { described_class.image_params }

    it { is_expected.to be_an(Array) }
  end

  describe '#banner_image' do
    subject { instance.banner_image }

    it { is_expected.to be_a(Hyrax::AvatarUploader) }
  end

  described_class.instance_methods.grep(/_color$/).each do |color_method_name|
    describe "##{color_method_name}" do
      subject { instance.send(color_method_name) }

      it { is_expected.to match(/^#[0-9A-F]{6}/i) }
    end
  end
end
