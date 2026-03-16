# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to override the mail to
module Hyrax
  module ContactFormDecorator
    # Declare the e-mail headers. It accepts anything the mail method
    # in ActionMailer accepts.
    ###### OVERRIDE the to: field to add the Tenant's email, first
    def contact_email
      Site.account.contact_email_to
    end

    def headers
      ## OVERRIDE Hyrax 3.4.0 send the mail 'from' the submitter, which doesn't work on most smtp transports
      {
        subject: "#{Site.account.email_subject_prefix} #{email} #{subject}",
        to: contact_email,
        from: Site.account.contact_email,
        reply_to: email
      }
    end
  end
end

Hyrax::ContactForm.prepend(Hyrax::ContactFormDecorator)
