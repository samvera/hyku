# Generated via
#  `rails generate hyrax:work Image`

RSpec.describe Hyrax::ImageForm do
  let(:work) {Image.new}
  let(:form) {described_class.new(work, nil, nil)}
  let(:file_set) {FactoryGirl.create(:file_set)}

  describe ".model_attributes" do
    let(:params) {ActionController::Parameters.new(attributes)}
    let(:attributes) do
      {
          title: ['foo'],
          rendering_ids: [file_set.id],
          extent: ['extent']
      }
    end

    subject {described_class.model_attributes(params)}

    it 'permits parameters' do
      expect(subject['rendering_ids']).to eq [file_set.id]
      expect(subject['extent']).to eq ['extent']
    end

  end
end
