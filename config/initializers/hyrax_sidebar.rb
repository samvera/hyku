# frozen_string_literal: true

# Adds this app's entries to the dashboard sidebar through the registry Hyrax
# provides for it, so a section gains a link without this app carrying a copy of the
# sidebar partial and inheriting the job of re-syncing it.
Rails.application.config.to_prepare do
  # Assigned rather than appended: to_prepare runs again on every reload in
  # development, and << would register the same partial a second time.
  Hyrax::DashboardController.sidebar_partials[:repository_content] |=
    ['hyrax/dashboard/sidebar/controlled_vocabularies']
end
