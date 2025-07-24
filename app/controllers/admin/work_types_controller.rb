# frozen_string_literal: true

module Admin
  class WorkTypesController < ApplicationController
    layout 'hyrax/dashboard'

    before_action do
      authorize! :manage, Hyrax::Feature
    end

    def edit
      site
      setup_profile_work_types if Hyrax.config.flexible?
    end

    def update
      # Filter out work types not in profile when flexible metadata is enabled
      available_works = params[:available_works] || []
      available_works = filter_by_profile(available_works) if Hyrax.config.flexible?

      site.available_works = available_works
      if site.save
        flash[:notice] = "Work types have been successfully updated"
      else
        flash[:error] = "Work types were not updated"
      end

      setup_profile_work_types if Hyrax.config.flexible?
      render action: "edit"
    end

    private

    def site
      @site ||= Site.first
    end

    def setup_profile_work_types
      return unless Hyrax.config.flexible?

      profile = Hyrax::FlexibleSchema.current_version
      return unless profile

      profile_classes = profile['classes']&.keys || []
      @profile_work_types = profile_classes.map { |klass| klass.gsub(/Resource$/, '') } & Hyrax.config.registered_curation_concern_types
    end

    def filter_by_profile(available_works)
      return available_works unless Hyrax.config.flexible?

      profile = Hyrax::FlexibleSchema.current_version
      return available_works unless profile

      profile_classes = profile['classes']&.keys || []
      profile_work_types = profile_classes.map { |klass| klass.gsub(/Resource$/, '') } & Hyrax.config.registered_curation_concern_types

      # Only allow work types that are in the profile
      available_works & profile_work_types
    end
  end
end
