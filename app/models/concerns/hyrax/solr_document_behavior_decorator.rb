# frozen_string_literal: true
# OVERRIDE: Hyrax v5.0.1 to fix a bug
# previously presenter.file_set_presenters didn't know it
# had any files to display.
module Hyrax
  ##
  # @api public
  #
  # Hyrax extensions for +Blacklight+'s generated +SolrDocument+.
  #
  # @example using with +Blacklight::Solr::Document+
  #   class SolrDocument
  #     include Blacklight::Solr::Document
  #     include Hyrax::SolrDocumentBehavior
  #   end
  #
  # @see https://github.com/projectblacklight/blacklight/wiki/Understanding-Rails-and-Blacklight#models
  module SolrDocumentBehaviorDecorator
    # Method to return the model
    def hydra_model(classifier: nil)
      model = first('has_model_ssim')&.safe_constantize
      model = (first('has_model_ssim')&.+ 'Resource')&.safe_constantize if Hyrax.config.valkyrie_transition?
      model || model_classifier(classifier).classifier(self).best_model
    end
  end
end

Hyrax::SolrDocumentBehavior.prepend(Hyrax::SolrDocumentBehaviorDecorator)
