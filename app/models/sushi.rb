# frozen_string_literal:true

require 'sushi/error'

module Sushi
  mattr_accessor :info

  class << self
    ##
    # @param dates [Array<String>]
    # @raise [Sushi::InvalidParameterValue] when either of the given dates are not formatted correctly.
    #
    # @return [TrueClass]
    #
    # @note This is necessary because calling `to_date` on a string in 'MM-YYYY' format will assume that 'MM' is the day,
    #       and will set the current month as 'MM' instead.
    #
    #       params.fetch(:begin_date) => "06-2023"
    #       params.fetch(:begin_date).to_date => Wed, 06 Sep 2023
    def validate_date_format(dates = [])
      dates.each do |date|
        match = date.match(/(^\d{4}-\d{2}$)|(^\d{4}-\d{2}-\d{2}$)/)
        raise Sushi::Error::InvalidDateArgumentError.new(data: "The given date of \"#{date}\" is invalid. Please provide a date in YYYY-MM format") unless match

        # rubocop:disable Layout/LineLength
        info << Sushi::Info.new(data: date.to_s, message: "The day of the month is not taken into consideration when providing metrics. The date provided was amended to account for the full month.").as_json if match[2]
        # rubocop:enable Metrics/MethodLength
      end

      true
    end

    ##
    # @param value [String, #to_date]
    #
    # @return [Date]
    # @raise [Sushi::InvalidParameterValue] when we cannot coerce to a date.
    def coerce_to_date(value)
      value.to_date
    rescue StandardError
      begin
        # We can't parse the original date, so lets attempt to coerce a "YYYY-MM" string (year-month).
        # If it fails, we'll raise an exception on garbage input.
        year, month, = value.split('-')

        # We want to set the date to the 1st of the month.
        Date.new(year.to_i, month.to_i, 1)
      rescue StandardError
        raise Sushi::Error::InvalidDateArgumentError.new(data: "Unable to convert \"#{value}\" to a date.")
      end
    end

    ##
    # The first day of the month of the earliest entry in {Hyrax::CounterMetric}, with some caveats.
    #
    # Namely if we only have one month of data, and that month happens to be the current month.
    #
    # @param current_date [Date] included as a dependency injection to ease testing.
    #
    # @return [Date] when we have data in the system
    # @raise [Sushi::Error::UsageNotReadyForRequestedDatesError] when we don't have data in the
    #         system OR we only have data for the current month.
    #
    # @see {.last_month_available}
    #
    # @note Ultimately, the goal of these date ranges is for us to inform the consumer of the API
    #       about the complete months of data that we have.
    def first_month_available(current_date: Time.zone.today)
      raise Sushi::Error::UsageNotReadyForRequestedDatesError.new(data: "There is no available metrics data available at this time.") unless Hyrax::CounterMetric.any?

      # If, for some reason, we have only partial data for the earliest month, we'll assume that
      # we have "all" that month's data.
      earliest_entry_beginning_of_month_date = Hyrax::CounterMetric.order('date ASC').first.date.beginning_of_month

      beginning_of_month = current_date.beginning_of_month

      # In this case, the only data we have is data in the current month and since the current month
      # isn't over we should not be reporting.
      if earliest_entry_beginning_of_month_date == beginning_of_month
        raise Sushi::Error::UsageNotReadyForRequestedDatesError.new(data: "The only data available is for #{beginning_of_month.strftime('%Y-%m')}; a month that is not yet over.")
      end

      earliest_entry_beginning_of_month_date
    end

    ##
    # @see .first_month_available
    #
    # @return [String] when there is a valid first month, return the YYYY-MM format of that month.
    # @return [NilClass] when there is not a valid first month
    def rescued_first_month_available(*args)
      first_month_available(*args).strftime("%Y-%m")
    rescue Sushi::Error::UsageNotReadyForRequestedDatesError
      nil
    end

    ##
    # The earlier of:
    #
    # - the last day of the prior month
    # - the last day of the month of the latest entry in {Hyrax::CounterMetric}
    #
    # @param current_date [Date] included as a dependency injection to ease testing.  An assumption
    #        is that the current_date will always be on or after the last {Hyrax::CounterMetric}
    #        entry's date.
    #
    # @return [Date] when we have data in the system
    # @raise [Sushi::Error::UsageNotReadyForRequestedDatesError] when we don't have data in the
    #        system
    #
    # @see {.first_month_available}
    #
    # @note Ultimately, the goal of these date ranges is for us to inform the consumer of the API
    #       about the complete months of data that we have.
    def last_month_available(current_date: Time.zone.today)
      # This might raise an exception
      first_month_available(current_date:)

      # We're assuming that we have whole months, so we'll nudge the latest date towards that
      # assumption.
      latest_entry_end_of_month_date = Hyrax::CounterMetric.order('date DESC').first.date.end_of_month

      # We want to avoid partial months, we look at the month prior to the current_date
      end_of_last_month = 1.month.ago(current_date).end_of_month

      return latest_entry_end_of_month_date if latest_entry_end_of_month_date < end_of_last_month

      end_of_last_month
    end

    ##
    # @see .last_month_available
    #
    # @return [String] when there is a valid last month, return the YYYY-MM format of that month.
    # @return [NilClass] when there is not a valid last month
    def rescued_last_month_available(*args)
      last_month_available(*args).strftime("%Y-%m")
    rescue Sushi::Error::UsageNotReadyForRequestedDatesError
      nil
    end
  end

  ##
  # This module provides a common interface for validating parameters.
  #
  # @param params [Hash, ActionController::Parameters]
  # @param allowed_parameters [Array<String>] a list of query parameters AND report filters that are allowed.
  #
  # @return [String]
  # @raise [Sushi::Error::UnrecognizedParameterError] when any unrecognized params are given.
  module ParameterValidation
    def validate_paramaters(params = {}, allowed_parameters: [])
      filtered_params = params.keys.map(&:to_s) - ['action', 'controller', 'format']
      return true if (filtered_params & allowed_parameters).length == filtered_params.length

      raise Sushi::Error::UnrecognizedParameterError.new(data: "The given parameter(s) are invalid: #{(filtered_params - allowed_parameters).join(', ')}.")
    end
  end

  ##
  # This module accounts for date behavior that needs to be used across all reports.
  #
  # @see #coerce_dates
  module DateCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :begin_date
      attr_reader :end_date
    end

    ##
    # @param params [Hash, ActionController::Parameters]
    # @option params [String, NilClass] begin_date :: Either nil, YYYY-MM or YYYY-MM-DD format
    # @option params [String, NilClass] end_date :: Either nil, YYYY-MM or YYYY-MM-DD format
    #
    # @raise [Sushi::Error::InvalidDateArgumentError] when begin date is after end date
    # @raise [Sushi::Error::UsageNoLongerAvailableForRequestedDatesError] when given begin date
    #        (coerced to beginning of month) is before earliest reporting date.
    # @raise [Sushi::Error::UsageNoLongerAvailableForRequestedDatesError] when given end date
    #        (coerced to end of month) is after latest reporting date.
    # @raise [Sushi::Error::InsufficientInformationToProcessRequestError] when either end date or
    #        begin date is not given.
    def coerce_dates(params = {})
      # TODO: We should also be considering available dates as well.

      Sushi.validate_date_format([params.fetch(:begin_date), params.fetch(:end_date)])

      # Because we're receiving user input that is likely strings, we need to do some coercion.
      @begin_date = Sushi.coerce_to_date(params.fetch(:begin_date)).beginning_of_month
      @end_date = Sushi.coerce_to_date(params.fetch(:end_date)).end_of_month

      raise Sushi::Error::InvalidDateArgumentError.new(data: "Begin date #{params.fetch(:begin_date)} is after end date #{params.fetch(:end_date)}.") if @begin_date > @end_date

      earliest_date = Hyrax::CounterMetric.order(date: :asc).first.date
      if @begin_date < earliest_date
        # rubocop:disable Layout/LineLength
        raise Sushi::Error::UsageNoLongerAvailableForRequestedDatesError.new(data: "Unable to complete the request because the begin_date of #{params[:begin_date]} is for a month that has incomplete data.  That month's data starts on #{earliest_date.iso8601}.")
        # rubocop:enable Metrics/MethodLength
      end

      latest_date = Hyrax::CounterMetric.order(date: :desc).first.date
      if @end_date > latest_date
        # rubocop:disable Layout/LineLength
        raise Sushi::Error::UsageNotReadyForRequestedDatesError.new(data: "Unable to complete the request because the end_date of #{params[:end_date]} is for a month that has incomplete data.  That month's data ends on #{latest_date.iso8601}.")
        # rubocop:enable Metrics/MethodLength
      end
    # rubocop:disable Lint/ShadowedException
    rescue ActionController::ParameterMissing, KeyError => e
      # rubocop:enable Lint/ShadowedException
      raise Sushi::Error::InsufficientInformationToProcessRequestError.new(data: e.message)
    end
  end

  ##
  # This module provides coercion of the :data_type parameter
  #
  # @see #coerce_data_types
  module DataTypeCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :data_types, :data_type_in_params
    end

    ##
    # @param params [Hash, ActionController::Parameters]
    # @option params [String, NilClass] data_type :: Pipe separated string of one or more data_types.
    def coerce_data_types(params = {})
      @data_type_in_params = params.key?(:data_type)
      @data_types = Array.wrap(params[:data_type]&.split('|')).map { |dt| dt.strip.downcase }
    end
  end

  module MetricTypeCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :metric_types, :metric_type_in_params
    end

    # rubocop:disable Metrics/MethodLength
    def coerce_metric_types(params = {}, allowed_types: ALLOWED_METRIC_TYPES)
      metric_types_from_params = Array.wrap(params[:metric_type]&.split('|'))
      return @metric_types = allowed_types if metric_types_from_params.empty?

      @metric_type_in_params = metric_types_from_params.any? do |metric_type|
        normalized_metric_type = metric_type.downcase
        allowed_types.any? { |allowed_type| allowed_type.downcase == normalized_metric_type }
      end

      unless metric_type_in_params
        raise Sushi::Error::InvalidReportFilterValueError.given_value_does_not_match_allowed_values(
          parameter_value: params[:metric_type],
          parameter_name: :metric_type,
          allowed_values: allowed_types
        )
      end

      @metric_types = metric_types_from_params.map do |metric_type|
        normalized_metric_type = metric_type.downcase
        metric_type.titleize.tr(' ', '_') if allowed_types.any? { |allowed_type| allowed_type.downcase == normalized_metric_type }
      end.compact
    end
    # rubocop:enable Metrics/MethodLength
  end

  module AccessMethodCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :access_methods, :access_method_in_params
    end

    ALLOWED_ACCESS_METHODS = ['regular'].freeze

    ##
    # @param params [Hash, ActionController::Parameters]
    #
    # @return [Array<String>]
    # @raise [Sushi::InvalidParameterValue] when the access method is invalid.
    def coerce_access_method(params = {})
      return true unless params.key?(:access_method)
      allowed_access_methods_from_params = Array.wrap(params[:access_method].split('|')).map { |am| am.strip.downcase } & ALLOWED_ACCESS_METHODS

      unless allowed_access_methods_from_params.any?
        raise Sushi::Error::InvalidReportFilterValueError.given_value_does_not_match_allowed_values(
          parameter_value: params[:access_method],
          parameter_name: :access_method,
          allowed_values: ALLOWED_ACCESS_METHODS
        )
      end

      @access_methods = allowed_access_methods_from_params
      @access_method_in_params = true
    end
  end

  module ItemIDCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :item_id, :item_id_in_params
    end

    ##
    # @param params [Hash, ActionController::Parameters]
    #
    # @return [String]
    # @raise [Sushi::Error::NotFoundError] when the item id has no metrics.
    def coerce_item_id(params = {})
      return true unless params.key?(:item_id)

      # rubocop:disable Layout/LineLength
      raise Sushi::Error::InvalidReportFilterValueError.new(data: "The given parameter `item_id=#{params[:item_id]}` does not exist. Please provide an existing item_id, or none at all.") unless Hyrax::CounterMetric.exists?(work_id: params[:item_id])
      # rubocop:enable Metrics/MethodLength

      @item_id = params[:item_id]
      @item_id_in_params = true
    end
  end

  module PlatformCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :platform, :platform_in_params
    end

    ##
    # @param params [Hash, ActionController::Parameters]
    # @param account [Account]
    #
    # @return [String]
    # @raise [Sushi::InvalidParameterValue] when the platform is invalid.
    def coerce_platform(params = {}, account = nil)
      return true unless params.key?(:platform)

      unless params[:platform] == account.cname
        raise Sushi::Error::InvalidReportFilterValueError.given_value_does_not_match_allowed_values(
          parameter_value: params[:platform],
          parameter_name: :platform,
          allowed_values: [account.cname]
        )
      end

      @platform = account.cname
      @platform_in_params = true
    end
  end

  # This param specifies the granularity of the usage data to include in the report.
  # Permissible values are Month (default) and Totals.
  # For Totals, each Item_Performance element represents the aggregated usage for the reporting period.
  # See https://cop5.projectcounter.org/en/5.1/03-specifications/03-counter-report-common-attributes-and-elements.html#report-filters-and-report-attributes for details
  module GranularityCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :granularity, :granularity_in_params
    end
    ALLOWED_GRANULARITY = ["Month", "Totals"].freeze

    def coerce_granularity(params = {})
      return true unless params.key?(:granularity)
      @granularity_in_params = ALLOWED_GRANULARITY.include?(params[:granularity].to_s.capitalize)

      unless @granularity_in_params
        raise Sushi::Error::InvalidReportFilterValueError.given_value_does_not_match_allowed_values(
          parameter_value: params[:granularity],
          parameter_name: :granularity,
          allowed_values: ALLOWED_GRANULARITY
        )
      end

      @granularity = params.fetch(:granularity).capitalize
    end
  end

  module AuthorCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :author, :author_in_params
    end

    ##
    # Because we have the potential for multiple authors for a work, we want to separate those
    # authors in the single field.  We've chosen the pipe (e.g. `|`) as that delimiter.
    DELIMITER = "|"

    ##
    # Deserialize the Ruby array into a serialize author format.
    #
    # @param string [String]
    # @param delimiter [String]
    #
    # @see .serialize
    def self.deserialize(string, delimiter: DELIMITER)
      string.to_s.split(delimiter).select(&:present?)
    end

    ##
    # Convert the Ruby array into a serialize author format.
    #
    # @param array [Array<String>]
    # @param delimiter [String]
    #
    # @see .deserialize
    def self.serialize(array, delimiter: DELIMITER)
      array = Array.wrap(array)
      return nil if array.empty?

      "#{delimiter}#{array.join(delimiter)}#{delimiter}"
    end

    ##
    # Ensure the given param is valid.
    #
    # @param params [Hash, ActionController::Parameters]
    # @option params [String] :author the named parameter we'll use to filter the report items by.
    #
    # @note: The sushi spec states that this value must be >=2 characters. We're only enforcing that the value exactly
    #        matches whatever data we have in the database. Which presumably is >=2 characters, but may not be.
    #
    # @see #author_as_where_parameters
    def coerce_author(params = {})
      return true unless params.key?(:author)
      @author = params[:author]

      # See https://github.com/notch8/palni-palci/issues/721#issuecomment-1734215004 for details of this little nuance
      raise Sushi::Error::InvalidReportFilterValueError.new(data: "You may not query for multiple authors (as specified by the `#{DELIMITER}' delimiter.)") if @author.include?(DELIMITER)

      # rubocop:disable Layout/LineLength
      raise Sushi::Error::InvalidReportFilterValueError.new(data: "The given author #{author.inspect} was not found in the metrics.") unless Hyrax::CounterMetric.where(author_as_where_parameters).exists?
      # rubocop:enable Metrics/MethodLength

      @author_in_params = true
    end

    ##
    # @return [Array<String>] The {ActiveRecord::Base#where} can take an array of parameters, using
    #         those to build the SQL statement.  The returned values is conformant to that method's
    #         interface.
    #
    # @see .serialize
    # @see .deserialize
    def author_as_where_parameters
      # NOTE: I've included both the serialized handler and the non-serialized version; that way
      # when we send this code change up, we don't also need to perform a migration.
      #
      # TODO: Remove the "OR author = ?" and the 3rd element of the array once we've run the imports
      # with the latest changes brought about by the commit that introduced this comment.
      ["author LIKE ? OR author = ?", "%#{DELIMITER}#{author}#{DELIMITER}%", author]
    end
  end

  module YearOfPublicationCoercion
    extend ActiveSupport::Concern
    included do
      attr_reader :yop_as_where_parameters, :yop
    end

    DATE_RANGE_REGEXP = /^(\d+)\s*-\s*(\d+)$/

    ##
    # Convert the given params to parameters suitable for {ActiveRecord::Base.where} calls.
    #
    # @param params [Hash]
    # @option params [String] :yop the named parameter from which we'll extract integers.
    #
    # @return [Array<String,Integer>] when all of the parts are valid, we'll have an array with the
    #         first element being a string (that has position "?"s for SQL query building) and the
    #         remaining elements being integers.
    # @raise [ArgumentError] when part of the given YOP could not be coerced to an integer.
    #
    # @note No special consideration is made for date ranges that start with a later date and end with
    #       an earlier date (e.g. "1999-1994" will be "date >= 1999 AND date <= 1994"; which will
    #       return no entries.)
    # rubocop:disable Metrics/MethodLength
    def coerce_yop(params = {})
      return unless params.key?(:yop)

      # TODO: We might want to quote the column name and add the table name as well; this helps with
      #       any potential field name collisions while we assemble the SQL statement.
      field_name = 'year_of_publication'
      where_clauses = []
      where_values = []

      params[:yop].split(/\s*\|\s*/).flat_map do |slug|
        slug = slug.strip
        match = DATE_RANGE_REGEXP.match(slug)
        if match
          where_clauses << "(#{field_name} >= ? AND #{field_name} <= ?)"
          where_values << Integer(match[1])
          where_values << Integer(match[2])
        else
          where_clauses << "(#{field_name} = ?)"
          where_values << Integer(slug)
        end
      end
      @yop = params[:yop]
      @yop_as_where_parameters = ["(#{where_clauses.join(' OR ')})"] + where_values
    rescue ArgumentError
      # rubocop:disable Layout/LineLength
      raise Sushi::Error::InvalidDateArgumentError.new(data: "The given parameter `yop=#{yop}` was malformed.  You can provide a range (e.g. 'YYYY-YYYY') or a single date (e.g. 'YYYY').  You can separate ranges/values with a '|'.")
      # rubocop:enable Metrics/MethodLength
    end
    # rubocop: Metrics/MethodLength
  end
end
