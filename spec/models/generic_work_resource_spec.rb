# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe GenericWorkResource do
  subject(:work) { described_class.new }

  # TODO Register a test adapter
  # it_behaves_like 'a Hyrax::Work'

  describe '#creator' do
    it 'is ordered by user input' do
      work.creator = ["Jeremy", "Shana"]
      require 'byebug'; byebug

      expect(work.creator).to eq(["Jeremy", "Shana"])
    end
  end
end
