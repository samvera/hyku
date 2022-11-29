# OVERRIDE FILE from Hyrax v2.9.0
module Hyrax
  class UsersController < ApplicationController
    include Blacklight::SearchContext
    prepend_before_action :find_user, only: [:show]
    # OVERRIDE: AUTHORIZE A READER ROLE TO ACCESS A USERS INDEX AND SHOW
    before_action :users_match!, only: %i[show]
    authorize_resource class: '::User', instance_name: :user

    helper Hyrax::TrophyHelper

    def index
      authenticate_user! if Flipflop.hide_users_list?
      @users = search(params[:uq])
    end

    # Display user profile
    def show
      @presenter = Hyrax::UserProfilePresenter.new(@user, current_ability)
    end

    private

    # TODO: this should move to a service.
      # Returns a list of users excluding the system users and guest_users
      # @param query [String] the query string
      def search(query)
        clause = query.blank? ? nil : "%" + query.downcase + "%"
        base = ::User.where(*base_query)
        base = base.where("#{Hydra.config.user_key_field} like lower(?) OR display_name like lower(?)", clause, clause) if clause.present?
        base.registered
            .where("#{Hydra.config.user_key_field} not in (?)",
                   [::User.batch_user_key, ::User.audit_user_key])
            .references(:trophies)
            .order(sort_value)
            .page(params[:page]).per(10)
      end

      # You can override base_query to return a list of arguments
      def base_query
        [nil]
      end

      def find_user
        @user = ::User.from_url_component(params[:id])
        redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if @user.nil?
      end

      # OVERRIDE: AUTHORIZE A READER ROLE TO ACCESS A USERS INDEX AND SHOW
      def users_match!
        return if can?(:read, @user)
        return if current_user == @user

        raise CanCan::AccessDenied
      end

      def sort_value
        sort = params[:sort].blank? ? "name" : params[:sort]
        case sort
        when 'name'
          'display_name'
        when 'name desc'
          'display_name DESC'
        when 'login'
          Hydra.config.user_key_field
        when 'login desc'
          "#{Hydra.config.user_key_field} DESC"
        else
          sort
        end
      end
  end
end
