# frozen_string_literal: true

# Provides a default host for the current tenant
class HykuMailer < ActionMailer::Base
  def default_url_options
    { host: host_for_tenant }
  end

  def summary_email(user, messages, account)
    @user = user
    @messages = messages || []
    @account = account
    @url = notifications_url_for(@account)
    @application_name = account.sites.application_name

    mail(to: @user.email,
         subject: "You have #{@messages.count} new message(s) on #{@application_name}",
         from: @account.contact_email,
         template_path: 'hyku_mailer',
         template_name: 'summary_email')
  end

  private

  def host_for_tenant
    Account.find_by(tenant: Apartment::Tenant.current)&.cname || Account.admin_host
  end

  def notifications_url_for(account)
    "https://#{account.cname}/notifications"
  end
end
