# frozen_string_literal:true

# counter compliant format for the Platform Usage Report is found here: https://countermetrics.stoplight.io/docs/counter-sushi-api/82bd896d1dd60-pr-p1-platform-usage
#
# dates will be filtered by including the begin_date, and excluding the end_date
# e.g. if you want to full month, begin_date should be the first day of that month, and end_date should be the first day of the following month.
module Sushi
  # rubocop:disable Metrics/ClassLength
  class PlatformUsageReport
    attr_reader :created, :account
    include Sushi
    include Sushi::DataTypeCoercion
    include Sushi::DateCoercion
    include Sushi::MetricTypeCoercion
    include Sushi::ParameterValidation

    # the platform usage report only contains requests. see https://countermetrics.stoplight.io/docs/counter-sushi-api/mgu8ibcbgrwe0-pr-p1-performance-other for details
    ALLOWED_METRIC_TYPES = [
      "Searches_Platform",
      "Total_Item_Requests",
      "Unique_Item_Requests"
    ].freeze

    ALLOWED_PARAMETERS = [
      'access_method',
      'api_key',
      'begin_date',
      'customer_id',
      'end_date',
      'metric_type',
      'platform',
      'requestor_id'
    ].freeze

    def initialize(params = {}, created: Time.zone.now, account:)
      Sushi.info = []
      validate_paramaters(params, allowed_parameters: ALLOWED_PARAMETERS)
      coerce_data_types(params)
      coerce_dates(params)
      coerce_metric_types(params, allowed_types: ALLOWED_METRIC_TYPES)

      @created = created
      @account = account
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def as_json(_options = {})
      report_hash = {
        "Report_Header" => {
          "Release" => "5.1",
          "Report_ID" => "PR_P1",
          "Report_Name" => "Platform Usage",
          "Created" => created.rfc3339, # "2023-02-15T09:11:12Z"
          "Created_By" => account.institution_name,
          "Institution_ID" => account.institution_id_data,
          "Institution_Name" => account.institution_name,
          "Registry_Record" => "",
          "Report_Filters" => {
            "Begin_Date" => begin_date.iso8601,
            "End_Date" => end_date.iso8601,
            "Access_Method" => [
              "Regular"
            ]
          }
        },
        "Report_Items" => {
          "Platform" => account.cname,
          "Attribute_Performance" => attribute_performance_for_resource_types + attribute_performance_for_platform
        }
      }
      report_hash["Report_Header"]["Report_Filters"]["Data_Type"] = data_types if data_type_in_params
      report_hash["Report_Header"]["Report_Filters"]["Metric_Type"] = metric_types if metric_type_in_params
      report_hash["Report_Header"]["Exceptions"] = info if info.present?

      report_hash
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    alias to_hash as_json

    def attribute_performance_for_resource_types
      return [] if metric_type_in_params && metric_types.include?("Searches_Platform")

      data_for_resource_types.map do |record|
        {
          "Data_Type" => record.resource_type,
          "Access_Method" => "Regular",
          "Performance" => performance(record)
        }
      end
    end

    def performance(record)
      metric_types.each_with_object({}) do |metric_type, returning_hash|
        next if metric_type == "Searches_Platform"

        returning_hash[metric_type] = record.performance.each_with_object({}) do |cell, hash|
          hash[cell.fetch('year_month')] = cell.fetch(metric_type)
        end
      end
    end

    def attribute_performance_for_platform
      return [] if metric_type_in_params && metric_types.exclude?("Searches_Platform")

      [{
        "Data_Type" => "Platform",
        "Access_Method" => "Regular",
        "Performance" => {
          "Searches_Platform" => data_for_platform.each_with_object({}) do |record, hash|
            hash[record.year_month.strftime("%Y-%m")] = record.total_item_investigations
            hash
          end
        }
      }]
    end

    ##
    # @note the `date_trunc` SQL function is specific to Postgresql.  It will take the date/time field
    #       value and return a date/time object that is at the exact start of the date specificity.
    #
    #       For example, if we had "2023-01-03T13:14" and asked for the date_trunc of month, the
    #       query result value would be "2023-01-01T00:00" (e.g. the first moment of the first of the
    #       month).
    # rubocop:disable Layout/LineLength
    # rubocop:disable Metrics/MethodLength
    def data_for_resource_types
      # We're capturing this relation/query because in some cases, we need to chain another where
      # clause onto the relation.
      relation = Hyrax::CounterMetric
                 .select(:resource_type, :worktype,
                         %((SELECT To_json(Array_agg(Row_to_json(t)))
                           FROM
                           (SELECT
                           -- The AS field_name needs to be double quoted so as to preserve case structure.
                           SUM(total_item_investigations) as "Total_Item_Investigations",
                           SUM(total_item_requests) as "Total_Item_Requests",
                           COUNT(DISTINCT CASE WHEN total_item_investigations IS NOT NULL THEN CONCAT(work_id, '_', date::text) END) as "Unique_Item_Investigations",
                           COUNT(DISTINCT CASE WHEN total_item_requests IS NOT NULL THEN CONCAT(work_id, '_', date::text) END) as "Unique_Item_Requests",
                           -- We need to coerce the month from a single digit to two digits (e.g. August's "8" into "08")
                           CONCAT(DATE_PART('year', date_trunc('month', date)), '-', to_char(DATE_PART('month', date_trunc('month', date)), 'fm00')) AS year_month
                           FROM hyrax_counter_metrics AS aggr
                           WHERE #{Hyrax::CounterMetric.sanitize_sql_for_conditions(['aggr.resource_type = hyrax_counter_metrics.resource_type AND date >= ? AND date <= ?', begin_date, end_date])}
	               GROUP BY date_trunc('month', date)) t) as performance))
                 .where("date >= ? AND date <= ?", begin_date, end_date)
                 .order(resource_type: :asc)
                 .group(:resource_type, :worktype)

      return relation if data_types.blank?

      relation.where("LOWER(resource_type) IN (?)", data_types)
    end
    # rubocop:enable Layout/LineLength
    # rubocop:enable Metrics/MethodLength

    def data_for_platform
      Hyrax::CounterMetric
        .select("date_trunc('month', date) AS year_month",
                "SUM(total_item_investigations) as total_item_investigations",
                "SUM(total_item_requests) as total_item_requests")
        .where("date >= ? AND date <= ?", begin_date, end_date)
        .order("year_month")
        .group("date_trunc('month', date)")
    end
  end
  # rubocop:enable Metrics/ClassLength
end
