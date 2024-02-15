# frozen_string_literal: true

FactoryBot.define do
  factory :hyku_admin_set, parent: :admin_set do
    transient do
      permission_template_attributes do
        {
          manage_groups: [Ability.admin_group_name],
          deposit_groups: ['work_editor', 'work_depositor'],
          view_groups: ['work_editor']
        }
      end
    end
  end
end
