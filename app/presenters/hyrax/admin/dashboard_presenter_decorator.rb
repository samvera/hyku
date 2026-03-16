# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to fix user count. by joining roles, we keep the count correct even though there are many users
module Hyrax
  module Admin
    module DashboardPresenterDecorator
      # @return [Fixnum] the number of currently registered users
      def user_count(start_date, end_date)
        ::User.for_repository
              .where(guest: false)
              .where(created_at: start_date.to_date.beginning_of_day..end_date.to_date.end_of_day)
              .count
      end
    end
  end
end

Hyrax::Admin::DashboardPresenter.prepend(Hyrax::Admin::DashboardPresenterDecorator)
