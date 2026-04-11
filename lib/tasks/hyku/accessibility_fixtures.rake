# frozen_string_literal: true

namespace :hyku do
  namespace :accessibility do
    desc "Print rails console examples for realistic accessibility test data (works, collections, long metadata)"
    task console_examples: :environment do
      puts <<~MSG
        ----------------------------------------------------------------
        Hyku accessibility fixtures — use in development or staging

        Switch to the correct Apartment tenant first if multitenancy is enabled.

        Examples (rails console):

          User.joins(:roles).find_by("roles.name = ?", "admin") || FactoryBot.create(:admin)
          FactoryBot.valkyrie_create(:generic_work_resource,
            title: [('Long title ' * 20).strip],
            creator: [('Creator with a very long name ' * 3).strip])
          FactoryBot.valkyrie_create(:hyku_collection, :public,
            title: [('Public collection for a11y ' * 5).strip])

        Then run manual checks or Pa11y against URLs for those objects.

        See docs/accessibility/README.md (Pa11y / site-wide scan section)
        ----------------------------------------------------------------
      MSG
    end
  end
end
