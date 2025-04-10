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
  end
end
