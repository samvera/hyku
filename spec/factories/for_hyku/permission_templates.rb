# frozen_string_literal: true

FactoryBot.modify do
  # Modifying https://github.com/samvera/hyrax/blob/main/spec/factories/permission_templates.rb
  factory :permission_template do
    transient do
      manage_groups { [Ability.admin_group_name] }
      deposit_groups { ['work_editor', 'work_depositor'] }
      view_groups { ['work_editor'] }
    end

    trait :with_no_groups do
      manage_groups { [] }
      deposit_groups { [] }
      view_groups { [] }
    end
  end
end
