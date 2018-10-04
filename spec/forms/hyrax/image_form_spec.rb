# Generated via
# `rails generate hyrax:work Image`

RSpec.describe Hyrax::ImageForm do
  let(:work) { Image.new }
  let(:form) { described_class.new(work, nil, nil) }
  let(:file_set) { FactoryGirl.create(:file_set) }

  describe ".model_attributes" do
    subject { described_class.model_attributes(params) }

    let(:params) { ActionController::Parameters.new(attributes) }
    let(:attributes) do
      {
        title: ['foo'],
        rendering_ids: [file_set.id],
        extent: ['extent']
      }
    end

    it 'permits parameters' do
      expect(subject['rendering_ids']).to eq [file_set.id]
      expect(subject['extent']).to eq ['extent']
    end
  end

  include_examples("work_form")
end
