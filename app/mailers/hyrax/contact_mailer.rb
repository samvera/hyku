# frozen_string_literal: true

module Hyrax
  # Mailer for contacting the administrator
  class ContactMailer < HykuMailer
    def contact(contact_form)
      @contact_form = contact_form
      # Check for spam
      return if @contact_form.spam?
      headers = @contact_form.headers.dup
      headers[:subject] += " [#{host_for_tenant}]"
      mail(headers)
    end
  end
end
