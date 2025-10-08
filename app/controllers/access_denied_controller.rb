# frozen_string_literal: true

class AccessDeniedController < ApplicationController
  def show
    @reason = params[:reason]
    
    case @reason
    when 'metadata_profiles'
      @title = t('hyku.access_denied.metadata_profiles.title')
      @message = t('hyku.access_denied.metadata_profiles.message')
      @details = t('hyku.access_denied.metadata_profiles.details')
    else
      @title = t('hyku.access_denied.default.title', default: 'Access Denied')
      @message = t('hyku.access_denied.default.message', default: 'You do not have permission to access this resource.')
      @details = t('hyku.access_denied.default.details', default: 'Please contact your administrator if you believe this is an error.')
    end

    render :show, status: :forbidden
  end
end