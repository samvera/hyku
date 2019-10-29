# Generated via
#  `rails generate hyrax:work Oer`
require 'rails_helper'

RSpec.describe Hyrax::OerForm do
  let(:work) { Oer.new }
  let(:form) { described_class.new(work, nil, nil) }
  let(:file_set) { FactoryBot.create(:file_set) }

  describe ".model_attributes" do
    subject { described_class.model_attributes(params) }

    let(:params) { ActionController::Parameters.new(attributes) }
    let(:attributes) do
      {
        title: ['foo'],
        rendering_ids: [file_set.id],
        accessibility_feature: ['Alternative Text'],
        accessibility_hazard: ['Flashing'],
        accessibility_summary: ['Summary']
      }
    end

  end

  include_examples("work_form")

end
