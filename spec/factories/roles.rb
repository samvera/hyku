FactoryBot.define do
  factory :role do
    name { 'test_role' }

    factory :collection_manager_role do
      name          { 'collection_manager' }
      resource_id   { Site.instance.id }
      resource_type { 'Site' }
    end
  end
end
