# frozen_string_literal: true

# migrates models from AF to valkyrie
class MigrateResourcesJob < ApplicationJob
  # input [Array>>String] Array of ActiveFedora model names to migrate to valkyrie objects
  # defaults to AdminSet & Collection models if empty
  def perform(models: [])
    models = collection_models_list if models.empty?

    models.each do |model|
      model.constantize.find_each do |item|
        res = Hyrax.query_service.find_by(id: item.id)
        # start with a form for the resource
        fm = form_for(model:).constantize.new(resource: res)
        # save the form
        result = Hyrax::Transactions::Container[collection_model_event_mapping[model]]
                 .with_step_args(
                   'collection_resource.save_collection_banner' => { banner_unchanged_indicator: true },
                   'collection_resource.save_collection_logo' => { logo_unchanged_indicator: true }
                 ).call(fm)
        result.value!
      end
    end
  end

  def form_for(model:)
    model.to_s + 'ResourceForm'
  end

  def collection_models_list
    %w[AdminSet Collection]
  end

  def collection_model_event_mapping
    {
      'AdminSet' => 'admin_set_resource.update',
      'Collection' => 'change_set.update_collection'
    }
  end
end
