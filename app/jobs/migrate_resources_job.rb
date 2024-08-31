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
        puts "🦋🦋 Migrating #{model} #{res.title.first}, id: #{res.id.to_s} 🦋🦋"
        # start with a form for the resource
        fm = form_for(model:).constantize.new(resource: res)
        # save the form
        converted = Hyrax.persister.save(resource: fm)
        # reindex
        Hyrax.index_adapter.save(resource: converted)
      end
    end
  end

  def form_for(model:)
    model.to_s + 'ResourceForm'
  end

  def collection_models_list
    %w(AdminSet Collection)
  end
end
