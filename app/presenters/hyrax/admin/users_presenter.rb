# frozen_string_literal: true

module Hyrax
  module Admin
    class UsersPresenter
      # @return [Array] an array of Users
      def users
        @users ||= search
      end

      # @return [Number] quantity of users excluding the system users and guest_users
      def user_count
        users.count
      end

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

      def last_accessed(user)
        user.last_sign_in_at || user.created_at
      end

      # return [Boolean] true if the devise trackable module is enabled.
      def show_last_access?
        return @show_last_access unless @show_last_access.nil?
        @show_last_access = ::User.devise_modules.include?(:trackable)
      end

      private

      # Returns a list of users excluding the system users and guest_users
      def search
        ::User.registered.for_repository.without_system_accounts.uniq
      end
    end
  end
end
