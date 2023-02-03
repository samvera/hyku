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
        elsif work_depositor?
          can %i[create], all_work_types_and_files
        end
      end
    end
  end
end
