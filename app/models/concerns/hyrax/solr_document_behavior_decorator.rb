# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1 for correct return on #hydra_model

module Hyrax
  module SolrDocumentBehaviorDecorator
    # Remove this once https://github.com/samvera/hyrax/pull/6860 is merged
    def hydra_model(classifier: nil)
      model = first('has_model_ssim')&.safe_constantize
      model = (first('has_model_ssim')&.+ 'Resource')&.safe_constantize if Hyrax.config.valkyrie_transition?
      model || model_classifier(classifier).classifier(self).best_model
    end
  end
end

Hyrax::SolrDocumentBehavior.prepend(Hyrax::SolrDocumentBehaviorDecorator)
