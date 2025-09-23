# frozen_string_literal: true

Rails.application.console do
  case Account.count
  when 0
    Rails.logger.error "***** No accounts, found, please run the seeds *****"
  when 1
    switch!(Account.first)
    Rails.logger.error "***** Only one account found, switching to it automatically *****"
  else
    Rails.logger.error "***** Multiple accounts found, dont' forget to switch in to one with switch!(ACCOUNT_NAME) or switch!(ACCOUNT_CNAME) *****"
  end
end
