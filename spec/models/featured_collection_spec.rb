# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeaturedCollection do
  describe '.feature_limit' do
    subject { described_class.feature_limit }

    it { is_expected.to eq(6) }
  end
end
