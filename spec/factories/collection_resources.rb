# frozen_string_literal: true

FactoryBot.modify do
  factory :hyrax_collection do
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
