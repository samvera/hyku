# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CollectionResource do
  subject(:collection) { described_class.new }

  it_behaves_like 'a Hyrax::PcdmCollection'

  context 'with Hyrax::Permissions::Readable' do
    it { is_expected.to respond_to :public? }
    it { is_expected.to respond_to :private? }
    it { is_expected.to respond_to :registered? }
  end

  its(:internal_resource) { is_expected.to eq('Collection') }

  context 'class configuration' do
    subject { described_class }
    its(:to_rdf_representation) { is_expected.to eq('Collection') }
  end

  describe 'spec factories' do
    it 'creates a collection' do
      expect(FactoryBot.build(:hyku_collection)).to be_a(described_class)
    end
  end
end
