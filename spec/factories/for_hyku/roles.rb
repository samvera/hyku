# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    name { 'test_role' }

    trait :superadmin do
      name { 'superadmin' }
    end

    trait :site_role do
      resource_id   { Site.instance.id }
      resource_type { 'Site' }
    end

    trait :public do
      name { 'public' }
    end

    trait :admin do
      name { 'admin' }
      site_role
    end

    trait :work_editor do
      name { 'work_editor' }
      site_role
    end

    trait :work_depositor do
      name { 'work_depositor' }
      site_role
    end

    trait :collection_manager do
      name { 'collection_manager' }
      site_role
    end

    trait :collection_editor do
      name { 'collection_editor' }
      site_role
    end

    trait :collection_reader do
      name { 'collection_reader' }
      site_role
    end

    trait :user_manager do
      name { 'user_manager' }
      site_role
    end

    trait :user_reader do
      name { 'user_reader' }
      site_role
    end
  end
end
