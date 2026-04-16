# frozen_string_literal: true

module Admin
  class FieldMappingsController < ::Bulkrax::FieldMappingsController
    before_action -> { authorize! :manage, Site }

    helper_method :edit_field_mappings_path, :field_mappings_path

    def edit_field_mappings_path(**opts)
      main_app.edit_admin_field_mappings_path(**opts)
    end

    def field_mappings_path(**opts)
      main_app.admin_field_mappings_path(**opts)
    end

    protected

    def load_mappings
      Bulkrax.field_mappings.deep_dup
    end

    def save_mappings(hash)
      account = Site.account
      account.bulkrax_field_mappings = hash.to_json
      account.save!
    end

    def default_mappings
      Hyku.default_bulkrax_field_mappings.deep_dup
    end
  end
end
