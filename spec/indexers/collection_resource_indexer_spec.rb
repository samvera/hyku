# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe CollectionResourceIndexer do
  let(:indexer_class) { described_class }
  let(:resource)      { CollectionResource.new }

  it_behaves_like 'a Hyrax::Resource indexer'
end
