# frozen_string_literal:true

# counter compliant format for the Server Status Endpoint is found here: https://countermetrics.stoplight.io/docs/counter-sushi-api/f0dd30f814944-server-status
module Sushi
  class ServerStatus
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def server_status
      [
        {
          "Description" => "COUNTER Usage Reports for #{account.cname} platform.",
          "Service_Active" => true,
          "Registry_Record" => ""
        }
      ]
    end
  end
end
