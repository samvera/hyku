# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdminSetResource do
  subject(:admin_set) { described_class.new }

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

  context 'spec factoriers' do
    context ':hyku_admin_set' do
      it 'is an AdminSetResource' do
        expect(FactoryBot.build(:hyku_admin_set)).to be_a_kind_of(AdminSetResource)
      end

      it "creates an admin set and can create it's permission template" do
        expect do
          admin_set = FactoryBot.valkyrie_create(:hyku_admin_set, with_permission_template: true)
          expect(admin_set.permission_template).to be_a(Hyrax::PermissionTemplate)
          # It cannot create workflows
          expect(admin_set.permission_template.available_workflows).not_to be_present
        end.to change { Hyrax.query_service.count_all_of_model(model: described_class) }.by(1)
      end
    end
  end
end