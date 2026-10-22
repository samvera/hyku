# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeaturedWork, flexible: :either do
  its(:feature_limit) { is_expected.to eq(6) }
end
