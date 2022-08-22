# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  # Include any view helpers from your main app to use in mailers here
  helper ApplicationHelper
end
