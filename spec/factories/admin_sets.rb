# frozen_string_literal: true

FactoryBot.define do
  # Valkyrie AdminSet
  factory :hyku_admin_set, parent: :hyrax_admin_set do
    transient do
      with_permission_template { true }
      user { FactoryBot.create(:user) }
    end

    before(:create) do |admin_set, evaluator|
      Hyrax::Group.find_or_create_by!(name: ::Ability.admin_group_name)
    end
  end
end
