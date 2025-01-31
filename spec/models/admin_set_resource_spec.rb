# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdminSetResource do
  subject(:admin_set) { FactoryBot.valkyrie_create(:hyku_admin_set) }
  let!(:resource) { FactoryBot.valkyrie_create(:generic_work_resource, admin_set_id: admin_set.id) }

  it_behaves_like 'a Hyrax::AdministrativeSet'

  context 'with Hyrax::Permissions::Readable' do
    it { is_expected.to respond_to :public? }
    it { is_expected.to respond_to :private? }
    it { is_expected.to respond_to :registered? }
  end

  its(:internal_resource) { is_expected.to eq('AdminSet') }

  context 'class configuration' do
    subject { described_class }
    its(:to_rdf_representation) { is_expected.to eq('AdminSet') }
  end

  describe '#member_of' do
    it 'returns the resources in the admin set' do
      expect(subject.member_of).to eq [resource]
    end
  end

  describe '#member_collection_ids' do
    it 'returns the collection ids of the resources in the admin set' do
      expect(subject.member_collection_ids).to eq [resource.id]
    end
  end
end
