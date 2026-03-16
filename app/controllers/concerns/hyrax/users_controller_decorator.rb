# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 make sure users are authorized
module Hyrax
  module UsersControllerDecorator
    extend ActiveSupport::Concern

    included do
      before_action :users_match!, only: %i[show] # rubocop:disable Rails/LexicallyScopedActionFilter
      authorize_resource class: '::User', instance_name: :user
    end

    private

    def users_match!
      # The #find_user method is a :before_action on the Hyrax::UsersController. It sets
      # the @user variable, which we need in this method.
      #
      # However, because we are decorating Hyrax::UsersController with this module,
      # this method's :before_action will fire before the one that calls #find_user.
      # This means that #find_user will fire a second time after this method runs.
      #
      # This is not ideal, but after discussing with @jeremyf, we decided that this is
      # the "lesser evil" compared to other override methods (i.e. using #class_eval,
      # overriding the entire file, etc.); since User is an ActiveRecord object, the
      # database query that sets @user in #find_user will be cached.
      #
      # Classes that inherit from Hyrax::UsersController do not have this problem
      # (e.g. Hyrax::Dashboard::ProfilesController), which is why we check for presence.
      find_user if @user.blank?

      return if can?(:read, @user)
      return if current_user == @user

      raise CanCan::AccessDenied
    end
  end
end

Hyrax::UsersController.include(Hyrax::UsersControllerDecorator)
