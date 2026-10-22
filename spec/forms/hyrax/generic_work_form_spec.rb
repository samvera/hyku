# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work GenericWork`
RSpec.describe Hyrax::GenericWorkForm, flexible: :either do
  let(:work) { GenericWork.new }
  let(:form) { described_class.new(work, nil, nil) }
  let(:file_set) { FactoryBot.create(:file_set) }

  # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
  # an ActiveFedora FileSet has no transcript_ids (issue #3418).
  describe ".model_attributes", flexible: false do
    subject { described_class.model_attributes(params) }

    let(:params) { ActionController::Parameters.new(attributes) }
    let(:attributes) do
      {
        title: ['foo'],
        rendering_ids: [file_set.id]
      }
    end

    it 'permits parameters' do
      expect(subject['rendering_ids']).to eq [file_set.id]
    end
  end

  include_examples("work_form")
end
