# frozen_string_literal: true

# Extending https://github.com/samvera/hyrax/blob/main/spec/factories/administrative_sets.rb
FactoryBot.modify do
  factory :hyrax_admin_set do
    transient do
      # We need FactoryBot declaration, otherwise we use the same strategy
      # (e.g. FactoryBot.valkyrie_create), and stumble into a nightmare.
      user { FactoryBot.create(:user) }
    end
  end
end

FactoryBot.define do
  # Create an AdminSetResource and it's corresponding permission template.
  #
  # ```ruby
  # FactoryBot.valkyrie_create(:hyku_admin_set, with_permission_template: true)
  # ```
  factory :hyku_admin_set, parent: :hyrax_admin_set, class: Hyrax.config.admin_set_model do
    transient do
      # We need FactoryBot declaration, otherwise we use the same strategy
      # (e.g. FactoryBot.valkyrie_create), and stumble into a nightmare.
      user { FactoryBot.create(:user) }
    end
  end
end
