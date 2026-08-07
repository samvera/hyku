# frozen_string_literal: true

# N+1 / unused-eager-load detection. Only instruments genuine ActiveRecord
# association loading (Account, collection_type_participants,
# permission_template_accesses, good_jobs, etc.) - it does NOT see Valkyrie-backed
# Hyrax::Work queries against orm_resources, since those go through Valkyrie's
# query service rather than AR associations. Complementary to, not a replacement
# for, Postgres-level pg_stat_statements/log_min_duration_statement analysis.
if Rails.env.development? || Rails.env.staging?
  require 'bullet'

  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true
      Bullet.rails_logger = true

      Bullet.add_footer = true if Rails.env.development?
    end
  end
end
