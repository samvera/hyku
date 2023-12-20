# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::Forms::Admin::Appearance do
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
end
