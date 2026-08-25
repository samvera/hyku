# frozen_string_literal: true

# Adds this app's entries to the dashboard sidebar through the registry Hyrax
# provides for it, so a section gains a link without this app carrying a copy of the
# sidebar partial and inheriting the job of re-syncing it.
#
# Offered in development and on staging, withheld from production while the
# vocabulary dashboard is still settling. The pages stay reachable by url either
# way; this only decides whether staff are shown a link to them.
#
# Staging opts in through HYKU_VOCABULARY_SIDEBAR_ENABLED=true rather than
# Rails.env.staging? - staging deployments run with RAILS_ENV=production (see
# config/initializers/bullet.rb), so staging.rb never loads there and Rails.env
# cannot tell the two apart. Production simply leaves the variable unset.
if Rails.env.development? || Rails.env.test? ||
   ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_VOCABULARY_SIDEBAR_ENABLED', 'false'))
  Rails.application.config.to_prepare do
    # Assigned rather than appended: to_prepare runs again on every reload in
    # development, and << would register the same partial a second time.
    Hyrax::DashboardController.sidebar_partials[:repository_content] |=
      ['hyrax/dashboard/sidebar/controlled_vocabularies']
  end
end
