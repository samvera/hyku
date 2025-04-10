# frozen_string_literal: true

require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe AdminSetResourceForm do
  let(:change_set) { described_class.new(resource) }
  let(:resource)   { AdminSetResource.new }

  it_behaves_like 'a Valkyrie::ChangeSet'
end
