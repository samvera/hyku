# frozen_string_literal: true

require Hyrax::Engine.root.join("spec/factories/administrative_sets").to_s
FactoryBot.modify do
  # Modifying https://github.com/samvera/hyrax/blob/main/spec/factories/administrative_sets.rb
  # Use: FactoryBot.valkyrie_create(:hyrax_admin_set)
  factory :hyrax_admin_set do
    transient do
      # We need FactoryBot declaration, otherwise we use the same strategy
      # (e.g. FactoryBot.valkyrie_create), and stumble into a nightmare.
      user { FactoryBot.create(:user) }
    end

    before(:create) do |_admin_set, _evaluator|
      Hyrax::Group.find_or_create_by!(name: ::Ability.admin_group_name)
    end
  end
end

FactoryBot.define do
  factory :hyku_admin_set, parent: :hyrax_admin_set
end
