# frozen_string_literal: true

# OVERRIDE FILE from Hyrax v5.2.0
# - Modify params to allow editing of additional User columns
# - Ensure the current user matches the requested URL.
module Hyrax
  module Dashboard
    module ProfilesControllerDecorator
      EMAIL_OPTIONS = ['never', 'daily', 'weekly', 'monthly'].freeze

      def frequency_options
        EMAIL_OPTIONS.map do |item|
          [I18n.t("hyrax.user_profile.email_frequency.#{item}"), item]
        end
      end

      private

      def user_params
        params.require(:user).permit(:batch_email_frequency, :avatar, :facebook_handle, :twitter_handle,
                                     :googleplus_handle, :linkedin_handle, :remove_avatar, :orcid)
      end
    end
  end
end

Hyrax::Dashboard::ProfilesController.prepend(Hyrax::Dashboard::ProfilesControllerDecorator)

##
# Ensure the current user matches the requested URL.
Hyrax::Dashboard::ProfilesController.before_action :users_match!, only: %i[show edit update]
