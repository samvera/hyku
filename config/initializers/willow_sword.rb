# frozen_string_literal: true

# Overriding the default config values
Rails.application.config.after_initialize do
  WillowSword.setup do |config|
    config.work_models = Hyrax.config.registered_curation_concern_types
    config.collection_models = [Hyrax.config.collection_model]
    config.file_set_models = [Hyrax.config.file_set_model]
    config.default_work_model = GenericWorkResource
    config.authorize_request = true
    config.xml_mapping_read = 'Hyku'
    # Subdirectory of tmp/network_files (already on the shared uploads PVC in k8s: friends, production, etc.)
    config.chunked_upload_path = Rails.root.join('tmp', 'network_files', 'willow_sword').to_s
  end
end
