# Hyrax's lib/hyrax/spec/factories provides the helpful support of the established factories of
# Hyrax, meaning we can then inherit from those
require Hyrax::Engine.root.join("spec/factories/permission_templates").to_s

FactoryBot.modify do
  # Modifying https://github.com/samvera/hyrax/blob/main/spec/factories/permission_templates.rb
  factory :permission_template do
    transient do
      manage_groups { [Ability.admin_group_name] }
      deposit_groups { ['work_editor', 'work_depositor'] }
      view_groups { ['work_editor'] }
    end
  end
end
