# Generated via
#  `rails generate hyrax:work Oer`
require 'rails_helper'

RSpec.describe Hyrax::OerForm do
  let(:work) { OerWork.new }
  let(:form) { described_class.new(work, nil, nil) }
  let(:file_set) { FactoryBot.create(:file_set) }

  describe ".model_attributes" do
    subject { described_class.model_attributes(params) }

    let(:params) { ActionController::Parameters.new(attributes) }
    let(:attributes) do
      {
        title: ['foo'],
        rendering_ids: [file_set.id]
      }
    end

  end

  include_examples("work_form")

end
