# Generated via
#  `rails generate hyrax:work Oer`
require 'rails_helper'

RSpec.describe Oer do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq OerIndexer }
  end

  it 'has a title' do
    subject.title = ['new oer work']
    expect(subject.title).to eq ['new oer work']
  end

  describe '.model_name' do
    subject { described_class.model_name.singular_route_key }

    it { is_expected.to eq 'hyrax_oer' }
  end

  describe ".properties" do
    subject { described_class.properties.keys }

    it { is_expected.to include("has_model", "create_date", "modified_date") }
  end

  describe "metadata" do
    it "has descriptive metadata" do
      expect(subject).to respond_to(:relative_path)
      expect(subject).to respond_to(:depositor)
      expect(subject).to respond_to(:related_url)
      expect(subject).to respond_to(:contributor)
      expect(subject).to respond_to(:creator)
      expect(subject).to respond_to(:title)
      expect(subject).to respond_to(:description)
      expect(subject).to respond_to(:publisher)
      expect(subject).to respond_to(:date_created)
      expect(subject).to respond_to(:date_uploaded)
      expect(subject).to respond_to(:date_modified)
      expect(subject).to respond_to(:subject)
      expect(subject).to respond_to(:language)
      expect(subject).to respond_to(:license)
      expect(subject).to respond_to(:resource_type)
      expect(subject).to respond_to(:identifier)
      expect(subject).to respond_to(:alternative_title)
      expect(subject).to respond_to(:date)
      expect(subject).to respond_to(:table_of_contents)
      expect(subject).to respond_to(:additional_information)
      expect(subject).to respond_to(:rights_holder)
      expect(subject).to respond_to(:oer_size)
      expect(subject).to respond_to(:accessibility_feature)
      expect(subject).to respond_to(:accessibility_hazard)
      expect(subject).to respond_to(:accessibility_summary)
    end
  end
end
