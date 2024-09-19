# frozen_string_literal: true

# migrates models from AF to valkyrie
class MigrateResourceService
  attr_accessor :resource
  def initialize(resource:)
    @resource = resource
  end

  def model
    @model || Wings::ModelRegistry.lookup(resource.class).to_s
  end

  def call
    prep_resource
    Hyrax::Transactions::Container[collection_model_event_mapping[model]]
      .with_step_args(**collection_model_steps_mapping[model]).call(resource_form)
  end

  def prep_resource
    case model
    when 'FileSet'
      resource.creator << ::User.batch_user.email if resource.creator.blank?
    end
  end

  def resource_form
    @resource_form ||= Hyrax::Forms::ResourceForm.for(resource: resource)
  end

  def collection_model_event_mapping
    {
      'AdminSet' => 'admin_set_resource.update',
      'Collection' => 'change_set.update_collection',
      'FileSet' => 'change_set.update_file_set'
    }
  end

  def collection_model_steps_mapping
    {
      'AdminSet' => {},
      'Collection' => {
        'collection_resource.save_collection_banner' => { banner_unchanged_indicator: true },
        'collection_resource.save_collection_logo' => { logo_unchanged_indicator: true }
      },
      'FileSet' => {
        'file_set.save_acl' => {}
      }
    }
  end
end
