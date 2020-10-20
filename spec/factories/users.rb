FactoryBot.define do
  factory :user, class: User do
    sequence(:email) { |_n| "email-#{srand}@test.com" }
    password { 'a password' }
    password_confirmation { 'a password' }

    ## NOTE(bkiahstroud)
    # A User's default Hyrax::Group membership(s) depend on what Role(s) it has.
    # Because Roles are associations, not traits, #add_default_group_memberships!
    # will not properly assign the User's intended Hyrax::Group
    # memberships until after the User has finished being created,
    # so we need to add the User's Roles before that happens.

    factory :admin do
      before(:create) do |user|
        user.add_role(:admin, Site.instance)
      end

      after(:build) do |user|
        user.add_role(:admin, Site.instance)
      end
    end

    factory :superadmin do
      before(:create) { |user| user.add_role(:superadmin) }
      after(:build)   { |user| user.add_role(:superadmin) }
    end

    factory :collection_manager do
      before(:create) do |user|
        user.add_role(:collection_manager, Site.instance)
      end

      after(:build) do |user|
        user.add_role(:collection_manager, Site.instance)
      end
    end

    factory :collection_editor do
      before(:create) do |user|
        user.add_role(:collection_editor, Site.instance)
      end

      after(:build) do |user|
        user.add_role(:collection_editor, Site.instance)
      end
    end

    factory :collection_reader do
      before(:create) do |user|
        user.add_role(:collection_reader, Site.instance)
      end

      after(:build) do |user|
        user.add_role(:collection_reader, Site.instance)
      end
    end

    factory :invited_user do
      after(:create, &:invite!)
    end

    factory :guest_user do
      guest { true }
    end
  end
end
