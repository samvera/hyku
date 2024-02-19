# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe GenericWorkResource do
  subject(:work) { described_class.new }

  # TODO: Register a test adapter
  it_behaves_like 'a Hyrax::Work'

  describe '#creator' do
    it 'is ordered by user input' do
      work.creator = ["Jeremy", "Shana"]

      # NOTE: This demonstrates how OrderAlready interacts with a ValkyrieResource.  It is possible
      # that we have an incorrect interaction, and this test is useless.  We'll know more as we work
      # through use cases.
      expect(work.attributes[:creator]).to eq(["0~Jeremy", "1~Shana"])

      expect(work.creator).to eq(["Jeremy", "Shana"])
    end
  end

  describe 'class configuration' do
    subject { described_class }

    its(:migrating_from) { is_expected.to eq(GenericWork) }
    its(:migrating_to) { is_expected.to eq(GenericWorkResource) }

    describe '.model_name' do
      subject { described_class.model_name }

      its(:klass) { is_expected.to eq GenericWorkResource }
      its(:name) { is_expected.to eq "GenericWorkResource" }

      its(:singular) { is_expected.to eq "generic_work" }
      its(:plural) { is_expected.to eq "generic_works" }
      its(:element) { is_expected.to eq "generic_work" }
      its(:human) { is_expected.to eq "Generic Work" }
      its(:collection) { is_expected.to eq "generic_works" }
      its(:param_key) { is_expected.to eq "generic_work" }
      its(:i18n_key) { is_expected.to eq :generic_work }
      its(:route_key) { is_expected.to eq "hyrax_generic_works" }
      its(:singular_route_key) { is_expected.to eq "hyrax_generic_work" }
    end
  end
end
