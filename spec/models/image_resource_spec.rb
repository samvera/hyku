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

      # NOTE: This demonstrates how OrderAlready interacts with a ValkyrieResource.  It is possible
      # that we have an incorrect interaction, and this test is useless.  We'll know more as we work
      # through use cases.
      expect(work.attributes[:creator]).to eq(["0~Jeremy", "1~Shana"])

      expect(work.creator).to eq(["Jeremy", "Shana"])
    end
  end

  describe 'class configuration' do
    subject { described_class }
    its(:migrating_from) { is_expected.to eq(Image) }
    its(:migrating_to) { is_expected.to eq(ImageResource) }

    context '.model_name' do
      subject { described_class.model_name }

      its(:klass) { is_expected.to eq ImageResource }
      its(:name) { is_expected.to eq "ImageResource" }

      its(:singular) { is_expected.to eq "image" }
      its(:plural) { is_expected.to eq "images" }
      its(:element) { is_expected.to eq "image" }
      its(:human) { is_expected.to eq "Image" }
      its(:collection) { is_expected.to eq "images" }
      its(:param_key) { is_expected.to eq "image" }
      its(:i18n_key) { is_expected.to eq :image }
      its(:route_key) { is_expected.to eq "hyrax_images" }
      its(:singular_route_key) { is_expected.to eq "hyrax_image" }
    end
  end
end
