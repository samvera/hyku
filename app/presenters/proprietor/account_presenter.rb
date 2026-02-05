# frozen_string_literal: true

module Proprietor
  # View-model for the proprietor account show page
  class AccountPresenter
    attr_reader :account

    delegate :cname, :admin_emails, :superadmin_emails, :public_demo_tenant, to: :account

    def initialize(account)
      @account = account
    end

    def last_admin?
      admin_emails.size == 1
    end

    def last_superadmin?(user)
      superadmin_emails.size == 1 && superadmin?(user)
    end

    def superadmin?(user)
      superadmin_emails.include?(user.email)
    end

    def can_remove_admin?(_user)
      !last_admin?
    end

    def can_remove_superadmin?(user)
      return true unless last_superadmin?(user)
      !public_demo_tenant
    end

    def admin_emails_without(user)
      admin_emails - [user.email]
    end

    def superadmin_emails_without(user)
      superadmin_emails - [user.email]
    end

    def superadmin_emails_with(user)
      superadmin_emails + [user.email]
    end
  end
end
