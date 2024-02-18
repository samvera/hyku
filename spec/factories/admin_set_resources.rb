# frozen_string_literal: true

# Extending https://github.com/samvera/hyrax/blob/main/spec/factories/administrative_sets.rb
FactoryBot.define do
  factory :hyku_admin_set, parent: :hyrax_admin_set, class: AdminSetResource do
    transient do
      # We need FactoryBot declaration, otherwise we use the same strategy
      # (e.g. FactoryBot.valkyrie_create), and stumble into a nightmare.
      user { FactoryBot.create(:user) }
    end
  end
end
