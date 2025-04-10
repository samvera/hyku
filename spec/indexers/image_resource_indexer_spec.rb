# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource ImageResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/indexers'

RSpec.describe ImageResourceIndexer do
  let(:indexer_class) { described_class }
  let!(:resource) { Hyrax.persister.save(resource: ImageResource.new) }

  it_behaves_like 'a Hyrax::Resource indexer'
end
