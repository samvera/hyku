# frozen_string_literal: true

module Sushi
  ##
  # A name space for the various errors that we have.
  #
  # @note I'd love for this to be Sushi::Error::Errors, but Rails autoload might have other opinions.
  module Error
    ##
    # @see https://countermetrics.stoplight.io/docs/counter-sushi-api/sgmqulr0emsi6-exception
    #
    # @see .as_json
    class Exception < StandardError
      class_attribute :code, default: nil
      class_attribute :help_url, default: nil
      class_attribute :default_message, default: nil

      attr_reader :data
      def initialize(data: nil)
        @data = data
        super("#{default_message}: #{data}")
      end

      ##
      # In Sushi's exception documentation there are two required properties:
      #
      # - Code :: an integer
      # - Message :: the Message value is a terse string that "identifies" the conceptual
      #
      # The Data property is the further explanation of the Message.  And the Help_URL property
      # is a URL that explains the exception.  By convention, we're setting the Help_URL to the
      # Sushi documentation; this helps developers read more about what the details of the
      # exceptions; and provides the end-user with further details about the Sushi "specification".
      #
      # @see https://countermetrics.stoplight.io/docs/counter-sushi-api/sgmqulr0emsi6-exception
      def as_json(*)
        hash = {
          Code: code,
          Message: default_message
        }

        hash[:Data] = data if data.present?
        hash[:Help_URL] = help_url if help_url.present?
        hash
      end
    end

    class InsufficientInformationToProcessRequestError < Sushi::Error::Exception
      self.code = 1030
      self.help_url = "https://countermetrics.stoplight.io/docs/counter-sushi-api/sgise2c2tmbrq-exception-1030"
      self.default_message = "Insufficient Information to Process Request"
    end

    class InvalidDateArgumentError < Sushi::Error::Exception
      self.code = 3020
      self.help_url = "https://countermetrics.stoplight.io/docs/counter-sushi-api/3anarphof7zh5-exception-3020"
      self.default_message = "Invalid Date Arguments"
    end

    class NoUsageAvailableForRequestedDatesError < Sushi::Error::Exception
      self.code = 3030
      self.help_url = "https://countermetrics.stoplight.io/docs/counter-sushi-api/2fhcc5gkzzkg3-exception-3030"
      self.default_message = "No Usage Available for Requested Dates"
    end

    # @todo This is likely a scenario we'll need to handle.
    class UsageNotReadyForRequestedDatesError < Sushi::Error::Exception
      self.code = 3031
      self.help_url = "https://countermetrics.stoplight.io/docs/counter-sushi-api/6lfhilgndgpde-exception-3031"
      self.default_message = "Usage Not Ready for Requested Dates"
    end

    # @todo This is likely a scenario we'll need to handle.
    class UsageNoLongerAvailableForRequestedDatesError < Sushi::Error::Exception
      self.code = 3032
      self.help_url = "https://countermetrics.stoplight.io/docs/counter-sushi-api/x2o44d5p9kdp3-exception-3032"
      self.default_message = "Usage No Longer Available for Requested Dates"
    end

    class UnrecognizedParameterError < Sushi::Error::Exception
      self.code = 3050
      self.help_url = "https://countermetrics.stoplight.io/docs/counter-sushi-api/mvg1sf79k34ni-exception-3050"
      self.default_message = "Parameter Not Recognized in this Context"
    end

    class InvalidReportFilterValueError < Sushi::Error::Exception
      self.code = 3060
      self.help_url = "https://countermetrics.stoplight.io/docs/counter-sushi-api/s2a2xb68jsnn6-exception-3060"
      self.default_message = "Invalid Report Filter Value"

      ##
      # @param parameter_value [#to_s]
      # @param parameter_name [#to_s]
      # @param allowed_values [Array<#to_s>]
      def self.given_value_does_not_match_allowed_values(parameter_value:, parameter_name:, allowed_values:)
        new(data: "None of the given values in `#{parameter_name}=#{parameter_value}` are supported at this time. " \
                  "Please use an acceptable value, (#{allowed_values.join(', ')}) instead. " \
                  "(Or do not pass the parameter at all, which will default to the acceptable value(s))")
      end
    end
  end

  ##
  # The Info exception differs from the Error exception in that it is returned in the Report_Header.
  # The message nor data are standarized, and therefore are being required to be passed in.
  class Info
    attr_reader :data, :message

    def initialize(data:, message:)
      @data = data
      @message = message
    end

    def as_json(*)
      {
        Code: 0,
        Message: message,
        Help_URL: "https://countermetrics.stoplight.io/docs/counter-sushi-api/jmelferytrixm-exception-0",
        Data: data
      }
    end
  end
end
