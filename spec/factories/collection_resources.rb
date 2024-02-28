# frozen_string_literal: true

FactoryBot.modify do
  factory :hyrax_collection do
    collection_type_gid { nil }
    creator { ["An Interesting Person"] }
    transient do
      # The `with_permission_template` transient does create a permission template, but it's
      # configuration is rather cumbersome.
      with_permission_template { true }

      collection_type_settings { nil }

      # See RolesService::CreateCollectionAccessesJob
      edit_groups { [Ability.admin_group_name, 'collection_manager'] }
      edit_users { [] }
      read_groups { ['collection_editor', 'collection_reader'] }
      read_users { [] }
    end

    before(:create) do |_collection, evaluator|
      (Array.wrap(evaluator.edit_groups) + Array.wrap(evaluator.read_groups)).each do |group|
        FactoryBot.create(:role, group.to_sym)
      end
    end

    after(:build) do |collection, evaluator|
      if collection.collection_type_gid.present?
        # Do nothing
      elsif evaluator.collection_type_settings.present?
        collection_type = FactoryBot.create(:collection_type, *evaluator.collection_type_settings)
        collection.collection_type = collection_type.to_global_id.to_s
      elsif collection.collection_type_gid.blank?
        collection_type = FactoryBot.create(:user_collection_type)
        collection.collection_type_gid = collection_type.to_global_id.to_s
      end
    end

    trait :with_member_works do
      # By default a Hyrax collection creates members with :hyrax_work; we don't likely want to
      # create that, so let's override that.
      transient do
        members { [FactoryBot.valkyrie_create(:generic_work_resource), FactoryBot.valkyrie_create(:generic_work_resource)] }
      end
    end
  end
end

FactoryBot.define do
  factory :hyku_collection, parent: :hyrax_collection, class: Hyrax.config.collection_class do
  end
end
