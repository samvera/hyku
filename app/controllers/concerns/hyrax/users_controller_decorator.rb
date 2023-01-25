# frozen_string_literal: true

module Hyrax
  module UsersControllerDecorator
    extend ActiveSupport::Concern

    included do
      before_action :users_match!, only: %i[show]
    end

    private

      def users_match!
        # TODO: explain why we're calling #find_user here
        find_user

        return if can?(:read, @user)
        return if current_user == @user

        raise CanCan::AccessDenied
      end
  end
end

Hyrax::UsersController.include(Hyrax::UsersControllerDecorator)
