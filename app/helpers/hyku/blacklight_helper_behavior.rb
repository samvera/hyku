# frozen_string_literal: true

# Override Blacklight v7.35.0 to add preferred view from search theme - Hyku Theming
# Methods added to this helper will be available to all templates in the hosting application
module Hyku
  module BlacklightHelperBehavior
    ##
    # Get the current "view type" (and ensure it is a valid type)
    #
    # @param [Hash] query_params the query parameters to check
    # @return [Symbol]
    def document_index_view_type(query_params = params)
      view_param = query_params[:view]
      view_param ||= search_results_theme.split('_').first
      view_param ||= session[:preferred_view]
      if view_param && document_index_views.key?(view_param.to_sym)
        view_param.to_sym
      else
        default_document_index_view_type
      end
    end

    # OVERRIDE: Blacklight::UrlHelperBehavior:
    #   override link_to_document to substitute method generate_work_url
    #   to fix URLs for gallery view groupings in shared tenants
    #     link_to_document(doc, 'VIEW', :counter => 3)
    # rubocop:disable Metrics/MethodLength
    def link_to_document(doc, field_or_opts = nil, opts = { counter: nil })
      label = case field_or_opts
              when NilClass
                document_presenter(doc).heading
              when Hash
                opts = field_or_opts
                document_presenter(doc).heading
              when Proc, Symbol
                Deprecation.warn(self, "passing a #{field_or_opts.class} to link_to_document is deprecated and will be removed in Blacklight 8")
                Deprecation.silence(Blacklight::IndexPresenter) do
                  index_presenter(doc).label field_or_opts, opts
                end
              else # String
                field_or_opts
              end

      # pull solr_document from input if we don't already have a solr_document
      document = doc&.try(:solr_document) || doc
      Deprecation.silence(Blacklight::UrlHelperBehavior) do
        link_to label, generate_work_url(document, request, params), document_link_params(document, opts)
      end
    end
    # rubocop:enable Metrics/MethodLength

    # OVERRIDE: Blacklight::UrlHelperBehavior:
    # disable link jacking for tracking
    # see https://playbook-staging.notch8.com/en/samvera/hyku/troubleshooting/multi-tenancy-and-full-urls
    # If we need to preserve the link jacking for tracking, then we need to also amend
    # method `session_tracking_params`so that instead of a path we have a URL
    # @private
    def document_link_params(_doc, opts)
      opts.except(:label, :counter, :q, :highlight)
    end
    private :document_link_params
  end
end
