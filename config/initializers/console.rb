# frozen_string_literal: true

Rails.application.console do
  case Account.count
  when 0
    puts "***** No accounts, found, please run the seeds *****"
  when 1
    switch!(Account.first)
    puts "***** Only one account found, switching to it automatically *****"
  else
    puts "***** Multiple accounts found, dont' forget to switch in to one with switch!(ACCOUNT_NAME) or switch!(ACCOUNT_CNAME) *****"
  end
end
