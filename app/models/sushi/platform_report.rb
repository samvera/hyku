# frozen_string_literal:true

# counter compliant format for the PlatformReport is found here: https://countermetrics.stoplight.io/docs/counter-sushi-api/e98e9f5cab5ed-pr-platform-report
#
# dates will be filtered where both begin & end dates are inclusive.
# any provided begin_date will be moved to the beginning of the month
# any provided end_date will be moved to the end of the month
module Sushi
  # rubocop:disable Metrics/ClassLength
  class PlatformReport
    attr_reader :created, :account, :attributes_to_show
    include Sushi
    include Sushi::AccessMethodCoercion
    include Sushi::DataTypeCoercion
    include Sushi::DateCoercion
    include Sushi::GranularityCoercion
    include Sushi::MetricTypeCoercion
    include Sushi::ParameterValidation
    include Sushi::PlatformCoercion

    ALLOWED_REPORT_ATTRIBUTES_TO_SHOW = [
      "Access_Method"
      # These are all the counter compliant query attributes, they are not currently supported in this implementation.
      # "Institution_Name",
      # "Customer_ID",
      # "Country_Name",
      # "Country_Code",
      # "Subdivision_Name",
      # "Subdivision_Code",
      # "Attributed"
    ].freeze

    ALLOWED_METRIC_TYPES = [
      "Searches_Platform",
      "Total_Item_Investigations",
      "Total_Item_Requests",
      "Unique_Item_Investigations",
      "Unique_Item_Requests"
      # Unique_Title metrics exist to count how many chapters or sections are accessed for Book resource types in a given user session.
      # This implementation currently does not support historical data from individual chapters/sections of Books,
      # so these metrics will not be shown.
      # See https://cop5.projectcounter.org/en/5.1/03-specifications/03-counter-report-common-attributes-and-elements.html#metric-types for details
      # "Unique_Title_Investigations",
      # "Unique_Title_Requests"
    ].freeze

    ALLOWED_PARAMETERS = [
      'access_method',
      'api_key',
      'attributed',
      'attributes_to_show',
      'author',
      'begin_date',
      'country_code',
      'customer_id',
      'data_type',
      'end_date',
      'granularity',
      'include_component_details',
      'include_parent_details',
      'item_id',
      'metric_type',
      'platform',
      'requestor_id',
      'subdivision_code',
      'yop'
    ].freeze

    def initialize(params = {}, created: Time.zone.now, account:)
      Sushi.info = []
      validate_paramaters(params, allowed_parameters: ALLOWED_PARAMETERS)
      coerce_access_method(params)
      coerce_data_types(params)
      coerce_dates(params)
      coerce_granularity(params)
      coerce_metric_types(params, allowed_types: ALLOWED_METRIC_TYPES)
      coerce_platform(params, account)
      @created = created
      @account = account

      # We want to limit the available attributes to be a subset of the given attributes; the `&` is
      # the intersection of the two arrays.
      @attributes_to_show = params.fetch(:attributes_to_show, ["Access_Method"]) & ALLOWED_REPORT_ATTRIBUTES_TO_SHOW
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def as_json(_options = {})
      report_hash = {
        "Report_Header" => {
          "Release" => "5.1",
          "Report_ID" => "PR",
          "Report_Name" => "Platform Report",
          "Created" => created.rfc3339, # "2023-02-15T09:11:12Z"
          "Created_By" => account.institution_name,
          "Institution_ID" => account.institution_id_data,
          "Institution_Name" => account.institution_name,
          "Registry_Record" => "",
          "Report_Attributes" => {
            "Attributes_To_Show" => attributes_to_show
          },
          "Report_Filters" => {
            # TODO: handle YYYY-MM format
            "Begin_Date" => begin_date.iso8601,
            "End_Date" => end_date.iso8601
          }
        },
        "Report_Items" => {
          "Platform" => account.cname,
          "Attribute_Performance" => attribute_performance_for_resource_types + attribute_performance_for_platform
        }
      }
      report_hash["Report_Header"]["Report_Filters"]["Access_Method"] = access_methods if access_method_in_params
      report_hash["Report_Header"]["Report_Filters"]["Data_Type"] = data_types if data_type_in_params
      report_hash["Report_Header"]["Report_Attributes"]["Granularity"] = granularity if granularity_in_params
      report_hash["Report_Header"]["Report_Filters"]["Metric_Type"] = metric_types if metric_type_in_params
      report_hash["Report_Header"]["Report_Filters"]["Platform"] = platform if platform_in_params
      report_hash["Report_Header"]["Exceptions"] = info if info.present?

      report_hash
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    alias to_hash as_json

    def attribute_performance_for_resource_types
      # We want to consider "or" behavior for multiple metric_types.  Namely if you specify any
      # metric type (other than Searches_Platform) you're going to get results.
      #
      # See https://github.com/notch8/palni-palci/issues/686#issuecomment-1785326034
      return [] if metric_type_in_params && (metric_types & (ALLOWED_METRIC_TYPES - ['Searches_Platform'])).count.zero?

      data_for_resource_types.map do |record|
        {
          "Data_Type" => record.resource_type,
          "Access_Method" => "Regular",
          "Performance" => performance(record)
        }
      end
    end

    # rubocop:disable Metrics/MethodLength
    def attribute_performance_for_platform
      return [] if metric_type_in_params && metric_types.exclude?("Searches_Platform")
      return [] if data_type_in_params && !data_types.find { |dt| dt.casecmp("Platform").zero? }

      [{
        "Data_Type" => "Platform",
        "Access_Method" => "Regular",
        "Performance" => {
          "Searches_Platform" => if granularity == 'Totals'
                                   total_for_platform = data_for_platform.sum(&:total_item_investigations)
                                   { "Totals" => total_for_platform }
                                 else
                                   data_for_platform.each_with_object({}) do |record, hash|
                                     hash[record.year_month.strftime("%Y-%m")] = record.total_item_investigations
                                     hash
                                   end
                                 end
        }
      }]
    end
    # rubocop:enable Metrics/MethodLength

    def performance(record)
      metric_types.each_with_object({}) do |metric_type, returning_hash|
        next if metric_type == "Searches_Platform"

        returning_hash[metric_type] =
          if granularity == 'Totals'
            { "Totals" => record.performance.sum { |hash| hash.fetch(metric_type) } }
          else
            record.performance.each_with_object({}) do |cell, hash|
              hash[cell.fetch('year_month')] = cell.fetch(metric_type)
            end
          end
      end
    end

    ##
    # @note the `date_trunc` SQL function is specific to Postgresql.  It will take the date/time field
    #       value and return a date/time object that is at the exact start of the date specificity.
    #
    #       For example, if we had "2023-01-03T13:14" and asked for the date_trunc of month, the
    #       query result value would be "2023-01-01T00:00" (e.g. the first moment of the first of the
    #       month).
    # also, note that unique_item_requests and unique_item_investigations should be counted for Hyrax::CounterMetrics that have unique dates, and unique work IDs.
    # see the docs for counting unique items here: https://cop5.projectcounter.org/en/5.1/07-processing/03-counting-unique-items.html
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
