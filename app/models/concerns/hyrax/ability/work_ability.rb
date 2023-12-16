# frozen_string_literal: true

module Hyrax
  module Ability
    module WorkAbility
      def work_roles
        all_work_types_and_files = Hyrax.config.curation_concerns + [::FileSet]

        if work_editor?
          can %i[read create edit update], all_work_types_and_files
          can %i[read edit update], ::SolrDocument do |solr_doc|
            all_work_types_and_files.include?(solr_doc.hydra_model)
          end
          can %i[read edit update], ::String do |id|
            doc = permissions_doc(id)
            all_work_types_and_files.include?(doc.hydra_model)
          end
        elsif work_depositor? || admin_set_with_deposit?
          can %i[create], all_work_types_and_files
        end
      end

      # OVERRIDE HYRAX 3.5.0 to return false if no ids are found
      # @return [Boolean] true if the user has at least one admin set they can deposit into.
      def admin_set_with_deposit?
        ids = PermissionTemplateAccess.for_user(ability: self,
                                                access: ['deposit', 'manage'])
                                      .joins(:permission_template)
                                      .select(:source_id)
                                      .distinct
                                      .pluck(:source_id)

        return false if ids.empty?

        Hyrax.custom_queries.find_ids_by_model(model: Hyrax::AdministrativeSet, ids:).any?
      end
    end
  end
end
