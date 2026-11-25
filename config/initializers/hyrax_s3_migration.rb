# frozen_string_literal: true

# Keeps the manifests written by Hyrax's S3 migration tasks (hyrax:migrate:files_to_s3 and friends)
# per tenant, so quarantine and rollback only touch the current tenant's files.
Rails.application.config.to_prepare do
  Hyrax::S3Migration.scope_provider = -> { Site.account&.cname } if defined?(Hyrax::S3Migration)
end
