# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax do
  describe '.config' do
    subject { described_class.config }

    # We're noticing behavior regarding factories that generate the wrong configured classes.
    # This spec is here to provide a similar type test.
    its(:admin_set_class) { is_expected.to eq(AdminSetResource) }
    its(:collection_class) { is_expected.to eq(CollectionResource) }

    # Regression check for samvera/hyku#3143: webm generation was dropped without a deprecation
    # period, breaking video playback that expects it. It must stay until the next major version.
    its(:derivative_options) { is_expected.to include(video: include(hash_including(label: 'webm'))) }
  end
end
