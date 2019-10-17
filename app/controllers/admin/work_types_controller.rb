module Admin
  class WorkTypesController < ApplicationController
    layout 'hyrax/dashboard'

    before_action do
      authorize! :manage, Hyrax::Feature
    end

    def edit
      site
    end

    def update
      site.available_works = params[:available_works]
      if site.save
        flash[:notice] = "Work types have been successfully updated"
      else
        flash[:error] = "Work types were not updated"
      end
      render action: "edit"
    end

    private

      def site
        @site ||= Site.first
      end
  end
end
