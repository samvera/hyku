# frozen_string_literal: true

if Gem::Version.new(BlacklightAdvancedSearch::VERSION) < Gem::Version.new('8.0.0')
  module BlacklightAdvancedSearch
    module AdvancedQueryParserDecorator
      # OVERRIDE: BlacklightAdvancedSearch v7.0.0
      #
      # Ensure @params has indifferent access. This resolves a bug where field-specific
      # queries (e.g. { title: "foo" }) weren't working because:
      # 1. @params was a Hash
      # 2. @params[:search_field] was being invoked while the expected value was in @params['search_field']
      # 3. The advanced search logic was short-circuited in #keyword_queries because @params[:search_field] was nil
      #
      # Reading the code in BlacklightAdvancedSearch, it's clear that @params is intended to have indifferent
      # access. Strangely, advanced search worked as expected in development mode; @params was a
      # ActiveSupport::HashWithIndifferentAccess in development mode as opposed to a Hash in production mode.
      #
      # @see BlacklightAdvancedSearch::QueryParser#keyword_queries
      #
      # TODO: Remove this override after upgrading to BlacklightAdvancedSearch v8.x.x;
      # it appears that @search_state will be used instead of @params.
      def initialize(params, config)
        super
        @params = @params.with_indifferent_access
      end
    end
  end

  BlacklightAdvancedSearch::QueryParser.prepend(BlacklightAdvancedSearch::AdvancedQueryParserDecorator)
end
