# frozen_string_literal: true

# OVERRIDE blacklight 6 to allow full url for show links for shared search and override blacklight url tracking
module Blacklight
  module UrlHelperBehaviorDecorator
    # override to use generate_work_url
    def link_to_document(doc, field_or_opts = nil, opts={:counter => nil})
      if field_or_opts.is_a? Hash
        opts = field_or_opts
      else
        field = field_or_opts
      end
  
      field ||= document_show_link_field(doc)
      label = index_presenter(doc).label field, opts
      link_to label, generate_work_url(doc, request), document_link_params(doc, opts)
    end

    # disable link jacking for tracking
    # see https://playbook-staging.notch8.com/en/samvera/hyku/troubleshooting/multi-tenancy-and-full-urls
    # If we need to preserve the link jacking for tracking, then we need to also amend
    # method `session_tracking_params`so that instead of a path we have a URL
    def document_link_params(doc, opts)
      opts.except(:label, :counter)
    end
  end
end

Blacklight::UrlHelperBehavior.prepend(Blacklight::UrlHelperBehaviorDecorator)
