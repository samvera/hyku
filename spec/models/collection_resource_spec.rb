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

  describe 'hide_from_catalog_search attribute' do
    it 'can get and set values' do
      expect(collection).to respond_to(:hide_from_catalog_search)
      expect(collection).to respond_to(:hide_from_catalog_search=)
    end

    it 'defaults to nil' do
      expect(collection.hide_from_catalog_search).to be nil
    end

    it 'can be set to true' do
      collection.hide_from_catalog_search = true
      expect(collection.hide_from_catalog_search).to be true
    end

    it 'can be set to false' do
      collection.hide_from_catalog_search = false
      expect(collection.hide_from_catalog_search).to be false
    end
  end
end
