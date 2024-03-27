# frozen_string_literal: true

require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe AdminSetResourceIndexer do
  let(:indexer_class) { described_class }
  let(:resource)      { AdminSetResource.new }

  it_behaves_like 'a Hyrax::Resource indexer'
end
