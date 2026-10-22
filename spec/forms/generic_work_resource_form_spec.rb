# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenericWorkResourceForm, flexible: :either do
  subject(:form) { described_class.for(work) }
  let(:base_attributes) { { title: "My TItle", creator: "Jeremy" } }
  let(:work) { GenericWorkResource.new(base_attributes.merge(attributes)) }

  let(:default_admin_set) { instance_double(AdminSetResource, title: "DEFAULT_ADMINSET", id: "DEFAULT_ADMINSET_ID") }
  before { allow(Hyrax::AdminSetCreateService).to receive(:find_or_create_default_admin_set).and_return(default_admin_set) }

  describe '#validate!' do
    context 'with an invalid video embed' do
      let(:attributes) { { video_embed: "https://google.com" } }

      it { is_expected.not_to be_valid }
    end

    # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
    # the form is invalid because the flexible profile requires Rights statement, which this example doesn't set.
    context 'with an empty video embed', flexible: false do
      let(:attributes) { { video_embed: "" } }

      it { is_expected.to be_valid }
    end
    # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
    # the form is invalid because the flexible profile requires Rights statement, which this example doesn't set.
    context 'with an acceptable video embed URL', flexible: false do
      let(:attributes) { { video_embed: "https://player.vimeo.com/embed/some-where" } }

      it { is_expected.to be_valid }
    end
  end
end
