# frozen_string_literal:true

# counter compliant format for ReportList: https://countermetrics.stoplight.io/docs/counter-sushi-api/af75bac10e789-report-list
module Sushi
  class ReportList
    # rubocop:disable Metrics/MethodLength, Layout/LineLength
    def as_json(_options = nil)
      [
        {
          "Report_Name" => "Server Status",
          "Report_ID" => "status",
          "Release" => "5.1",
          "Report_Description" => "This resource returns the current status of the reporting service supported by this API.",
          "Path" => "/api/sushi/r51/status"
        },
        {
          "Report_Name" => "Report List",
          "Report_ID" => "reports",
          "Release" => "5.1",
          "Report_Description" => "This resource returns a list of reports supported by the API for a given application.",
          "Path" => "/api/sushi/r51/reports"
        },
        {
          "Report_Name" => "Platform Report",
          "Report_ID" => "pr",
          "Release" => "5.1",
          "Report_Description" => "This resource returns COUNTER 'Platform Master Report' [PR]. A customizable report summarizing activity across a provider’s platforms that allows the user to apply filters and select other configuration options for the report.",
          "Path" => "/api/sushi/r51/reports/pr",
          "First_Month_Available" => Sushi.rescued_first_month_available,
          "Last_Month_Available" => Sushi.rescued_last_month_available
        },
        {
          "Report_Name" => "Platform Usage",
          "Report_ID" => "pr_p1",
          "Release" => "5.1",
          "Report_Description" => "This resource returns COUNTER 'Platform Usage' [pr_p1]. This is a Standard View of the Package Master Report that presents usage for the overall Platform broken down by Metric_Type.",
          "Path" => "/api/sushi/r51/reports/pr_p1",
          "First_Month_Available" => Sushi.rescued_first_month_available,
          "Last_Month_Available" => Sushi.rescued_last_month_available
        },
        {
          "Report_Name" => "Item Report",
          "Report_ID" => "ir",
          "Release" => "5.1",
          "Report_Description" => "This resource returns COUNTER 'Item Master Report' [IR].",
          "Path" => "/api/sushi/r51/reports/ir",
          "First_Month_Available" => Sushi.rescued_first_month_available,
          "Last_Month_Available" => Sushi.rescued_last_month_available
        }
      ]
    end
    alias to_hash as_json
    # rubocop:enable Metrics/MethodLength, Layout/LineLength
  end
end
