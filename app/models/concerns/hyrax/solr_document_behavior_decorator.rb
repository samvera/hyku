# frozen_string_literal: true

# OVERRIDE Hyrax 5.0.0rc2 to account for Valkyrie migration object that end in "Resource"

module Hyrax
  module SolrDocumentBehaviorDecorator
    def hydra_model(classifier: nil)
      if valkyrie?
        # In the future when we don't have Valkyrie migration objects,
        # we wouldn't have the SomethingResource naming convention, so we use super
        (first('has_model_ssim') + 'Resource')&.safe_constantize || super
      else
        super
      end
    end
  end
end

Hyrax::SolrDocumentBehavior.prepend(Hyrax::SolrDocumentBehaviorDecorator)
