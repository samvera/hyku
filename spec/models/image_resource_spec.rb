# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource ImageResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe ImageResource do
  subject(:work) { described_class.new }

  # it_behaves_like 'a Hyrax::Work'
  describe '#creator' do
    it 'is ordered by user input' do
      work.creator = ["Jeremy", "Shana"]

      # Note: This demonstrates how OrderAlready interacts with a ValkyrieResource.  It is possible
      # that we have an incorrect interaction, and this test is useless.  We'll know more as we work
      # through use cases.
      expect(work.attributes[:creator]).to eq(["0~Jeremy", "1~Shana"])

      expect(work.creator).to eq(["Jeremy", "Shana"])
    end
  end
end
