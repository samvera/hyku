# frozen_string_literal: true

FactoryBot.define do
  # TODO: swap this out for hyrax's collection_lw
  factory :collection do
    transient do
      user { create(:user) }
      # allow defaulting to default user collection
      collection_type_settings { nil }
      with_permission_template { false }
      create_access { false }
      with_nesting_attributes { nil }
    end
    sequence(:title) { |n| ["Collection Title #{n}"] }

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
      if evaluator.collection_type_settings.present?
        collection.collection_type = create(:collection_type, *evaluator.collection_type_settings)
      elsif collection.collection_type_gid.nil?
        collection.collection_type = create(:user_collection_type)
      end

      # if requested, create a solr document and add the nesting fields into it
      # when a nestable collection is built. This reduces the need to use
      # create and :with_nested_indexing for nested collection testing
      if evaluator.with_nesting_attributes.present? && collection.nestable?
        Hyrax::Adapters::NestingIndexAdapter.add_nesting_attributes(
          solr_doc: evaluator.to_solr,
          ancestors: evaluator.with_nesting_attributes[:ancestors],
          parent_ids: evaluator.with_nesting_attributes[:parent_ids],
          pathnames: evaluator.with_nesting_attributes[:pathnames],
          depth: evaluator.with_nesting_attributes[:depth]
        )
      end
    end

    after(:create) do |collection, evaluator|
      # create the permission template if it was requested, OR if nested reindexing is included
      # (so we can apply the user's permissions).  Nested indexing requires that the user's permissions
      # be saved on the Fedora object... if simply in local memory, they are lost when the adapter
      # pulls the object from Fedora to reindex.
      if evaluator.with_permission_template ||
         evaluator.create_access ||
         RSpec.current_example.metadata[:with_nested_reindexing]
        attributes = { source_id: collection.id }
        access = evaluator.create_access || RSpec.current_example.metadata[:with_nested_reindexing]
        attributes[:manage_users] = CollectionFactoryHelper.user_managers(evaluator.with_permission_template,
                                                                          evaluator.user,
                                                                          access)
        if evaluator.with_permission_template.respond_to?(:merge)
          attributes = evaluator.with_permission_template.merge(attributes)
        end
        create(:permission_template, attributes) unless Hyrax::PermissionTemplate.find_by(source_id: collection.id)
        collection.reset_access_controls!
      end
    end
  end
end
