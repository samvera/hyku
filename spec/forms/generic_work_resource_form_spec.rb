# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenericWorkResourceForm do
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

    context 'with an empty video embed' do
      let(:attributes) { { video_embed: "" } }

      it { is_expected.to be_valid }
    end
    context 'with an acceptable video embed URL' do
      let(:attributes) { { video_embed: "https://player.vimeo.com/embed/some-where" } }

      it { is_expected.to be_valid }
    end
  end
end
