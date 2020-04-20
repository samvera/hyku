# Copied from hyrax 2.5.1 to override the mail to
module Hyrax
  class ContactForm
    include ActiveModel::Model
    attr_accessor :contact_method, :category, :name, :email, :subject, :message
    validates :email, :category, :name, :subject, :message, presence: true
    validates :email, format: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i, allow_blank: true

    # - can't use this without ActiveRecord::Base validates_inclusion_of :category, in: self.class.issue_types_for_locale

    # They should not have filled out the `contact_method' field. That's there to prevent spam.
    def spam?
      contact_method.present?
    end

    # Declare the e-mail headers. It accepts anything the mail method
    # in ActionMailer accepts.
    ###### OVERRODE the to: field to add the Tenant's email, first
    def contact_email
      Site.contact_email.present? ?  Site.contact_email : Settings.contact_email_to
    end

    def headers
      ## override hyrax 2.5.1 send the mail 'from' the submitter, which doesnt work on most smtp transports
      {
        subject: "#{Hyrax.config.subject_prefix} #{email} #{subject}",
        to: self.contact_email,
        from: Settings.contact_email,
        reply_to: email
      }
    end

    def self.issue_types_for_locale
      [
        I18n.t('hyrax.contact_form.issue_types.depositing'),
        I18n.t('hyrax.contact_form.issue_types.changing'),
        I18n.t('hyrax.contact_form.issue_types.browsing'),
        I18n.t('hyrax.contact_form.issue_types.reporting'),
        I18n.t('hyrax.contact_form.issue_types.general')
      ]
    end
  end
end
