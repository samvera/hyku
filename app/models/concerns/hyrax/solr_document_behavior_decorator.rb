# frozen_string_literal: true

# OVERRIDE Hyrax 5.0.0rc2 to account for Valkyrie migration object that end in "Resource"

module Hyrax
  module SolrDocumentBehaviorDecorator
    def hydra_model(classifier: nil)
      if human_readable_type&.downcase&.strip&.ends_with?('resource')
        human_readable_type.titleize.delete(' ')&.safe_constantize ||
          model_classifier(classifier).classifier(self).best_model
      else
        super
      end
    end
  end
end

Hyrax::SolrDocumentBehavior.prepend(Hyrax::SolrDocumentBehaviorDecorator)
