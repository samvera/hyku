# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to accommodate groups and roles work
module Hyrax
  module Admin
    module UsersPresenterDecorator
      # @return [Array] an array of user roles
      def user_roles(user)
        user.ability.all_user_and_group_roles
      end

      # @return [Array] an array of user group role names
      def user_group_roles(user)
        user.group_roles
      end

      # @return [Array] an array of user added role names
      def user_site_roles(user)
        # if the user has a group role that is the same as the site role, we don't want to show the site role
        # because if it shows up as a site role and we can delete it, it will cause funky behavior
        user.site_roles - user_group_roles(user)
      end

      def user_groups(user)
        user.hyrax_groups
      end

      private

      # We can leverage
      def search
        super.for_repository.uniq
        # ::User.registered.for_repository.without_system_accounts.uniq
      end
    end
  end
end

Hyrax::Admin::UsersPresenter.prepend(Hyrax::Admin::UsersPresenterDecorator)
