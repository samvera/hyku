# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work Etd`
require 'rails_helper'

RSpec.describe Hyrax::EtdForm do
  let(:work) { Etd.new }
  let(:form) { described_class.new(work, nil, nil) }
  let(:file_set) { FactoryBot.create(:file_set) }

  describe ".model_attributes" do
    subject { described_class.model_attributes(params) }

    let(:params) { ActionController::Parameters.new(attributes) }
    let(:attributes) do
      {
        title: ['ETD Form Spec'],
        advisor: ['Advisor'],
        committee_member: ['Committee Member'],
        contributor: ['Contributor'],
        creator: ['Creator'],
        date_created: ['01/19/2021'],
        degree_discipline: ['Degree Discipline'],
        degree_grantor: ['Degree Grantor'],
        degree_level: ['Degree Level'],
        degree_name: ['Degree Name'],
        department: ['Department'],
        description: ['Description'],
        format: ['Format'],
        identifier: ['Identifier'],
        keyword: ['Keyword'],
        language: ['Language'],
        license: ['License'],
        publisher: ['Publisher'],
        related_url: ['Related URL'],
        resource_type: ['Masters Thesis'],
        rights_statement: 'http://rightsstatements.org/vocab/InC/1.0/',
        source: ['Source'],
        subject: ['Subject']
      }
    end

    # rubocop:disable RSpec/ExampleLength
    it 'permits parameters' do
      expect(subject['title']).to eq ['ETD Form Spec']
      expect(subject['advisor']).to eq ['Advisor']
      expect(subject['committee_member']).to eq ['Committee Member']
      expect(subject['contributor']).to eq ['Contributor']
      expect(subject['creator']).to eq ['Creator']
      expect(subject['date_created']).to eq ['01/19/2021']
      expect(subject['degree_discipline']).to eq ['Degree Discipline']
      expect(subject['degree_grantor']).to eq ['Degree Grantor']
      expect(subject['degree_level']).to eq ['Degree Level']
      expect(subject['degree_name']).to eq ['Degree Name']
      expect(subject['department']).to eq ['Department']
      expect(subject['description']).to eq ['Description']
      expect(subject['format']).to eq ['Format']
      expect(subject['identifier']).to eq ['Identifier']
      expect(subject['keyword']).to eq ['Keyword']
      expect(subject['language']).to eq ['Language']
      expect(subject['license']).to eq ['License']
      expect(subject['publisher']).to eq ['Publisher']
      expect(subject['related_url']).to eq ['Related URL']
      expect(subject['resource_type']).to eq ['Masters Thesis']
      expect(subject['rights_statement']).to eq 'http://rightsstatements.org/vocab/InC/1.0/'
      expect(subject['source']).to eq ['Source']
      expect(subject['subject']).to eq ['Subject']
    end
    # rubocop:enable RSpec/ExampleLength
  end

  include_examples("work_form")
end
