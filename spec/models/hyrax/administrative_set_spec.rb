# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::AdministrativeSet do
  describe 'factories' do
    context ':hyku_admin_set' do
      it 'successfully creates an admin set, admin group, and permission template' do
        expect do
          expect do
            expect do
              FactoryBot.valkyrie_create(:hyku_admin_set)
            end.to change { Hyrax::PermissionTemplate.count }.by(1)
          end.to change { Hyrax.query_service.count_all_of_model(model: Hyrax::AdministrativeSet) }.by(1)
        end.to change { Hyrax::Group.where(name: ::Ability.admin_group_name).count }.by(1)
      end
    end
  end
end
