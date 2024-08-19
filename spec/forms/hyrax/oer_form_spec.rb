# frozen_string_literal: true
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
        audience: ['instructor'],
        discipline: ['Engineering - Nuclear'],
        education_level: ['adult education'],
        learning_resource_type: ['Lecture notes'],
        resource_type: ['Collection'],
        date_created: ['10/3/2000'],
        alternative_title: ['alternative title'],
        table_of_contents: ['table of contents'],
        additional_information: ['additional information'],
        rights_holder: ['rights holder'],
        related_url: ['http://notch8.com'],
        oer_size: ['3 feet'],
        accessibility_feature: ['Alternative Text'],
        accessibility_hazard: ['Flashing']
      }
    end

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['rendering_ids']).to eq [file_set.id]
      expect(subject['audience']).to eq ["instructor"]
      expect(subject['discipline']).to eq ['Engineering - Nuclear']
      expect(subject['education_level']).to eq ['adult education']
      expect(subject['learning_resource_type']).to eq ['Lecture notes']
      expect(subject['resource_type']).to eq ['Collection']
      expect(subject['date_created']).to eq ['10/3/2000']
      expect(subject['alternative_title']).to eq ['alternative title']
      expect(subject['table_of_contents']).to eq ['table of contents']
      expect(subject['additional_information']).to eq ['additional information']
      expect(subject['rights_holder']).to eq ['rights holder']
      expect(subject['related_url']).to eq ['http://notch8.com']
      expect(subject['oer_size']).to eq ['3 feet']
      expect(subject['accessibility_feature']).to eq ['Alternative Text']
      expect(subject['accessibility_hazard']).to eq ['Flashing']
    end
  end

  include_examples("work_form")
end
