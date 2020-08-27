# frozen_string_literal: true

# override to fix user count. by joining roles, we keep the count correct even though there are many users
module Hyrax
  module Admin
    class DashboardPresenter
      # @return [Fixnum] the number of currently registered users
      def user_count
        ::User.registered.for_repository.without_system_accounts.uniq.count
      end

      def repository_objects
        @repository_objects ||= Admin::RepositoryObjectPresenter.new
      end

      def repository_growth
        @repository_growth ||= Admin::RepositoryGrowthPresenter.new
      end

      def user_activity
        @user_activity ||= Admin::UserActivityPresenter.new
      end
    end
  end
end
