# frozen_string_literal: true

FactoryBot.define do
  factory :group, class: Hyrax::Group do
    sequence(:name) { |_n| "group-#{srand}" }
    sequence(:humanized_name) { |_n| "Group #{name}" }
    sequence(:description) { |_n| "Somthing about group-#{srand}" }

    transient do
      member_users { [] }
      roles { [] }
    end

    after(:create) do |group, evaluator|
      evaluator.member_users.each do |user|
        group.add_members_by_id(user.id)
      end

      evaluator.roles.each do |role|
        group.roles << Role.find_or_create_by(
          name: role,
          resource_id: Site.instance.id,
          resource_type: 'Site'
        )
      end
    end

    factory :admin_group do
      name { 'admin' }
      humanized_name { 'Repository Administrators' }
      description { 'Default group' }

      roles { ['admin'] }
    end

    factory :registered_group do
      name { 'registered' }
      humanized_name { 'Registered Users' }
      description { 'Default group' }
    end

    factory :editors_group do
      name { 'editors' }
      humanized_name { 'Editors' }
      description { 'Default group' }

      roles { ['work_editor', 'collection_editor', 'user_reader'] }
    end

    factory :depositors_group do
      name { 'depositors' }
      humanized_name { 'Depositors' }
      description { 'Default group' }

      roles { ['work_depositor'] }
    end
  end
end
