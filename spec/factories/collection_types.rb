# frozen_string_literal: true

FactoryBot.modify do
  # Hyku assumes a collection editor and collection manager
  factory :collection_type do
    transient do
      creator_user { nil }
      creator_group { 'collection_editor' }
      manager_user { nil }
      manager_group { 'collection_manager' }
    end

    trait :without_default_participants do
      creator_user { nil }
      creator_group { nil }
      manager_user { nil }
      manager_group { nil }
    end
  end
end
