# frozen_string_literal: true

module API
  class SushiController < ApplicationController
    private

    ##
    # We have encountered an error in their request, this might be an invalid date or a missing
    # required parameter.  The end user can adjust the request and try again.
    #
    # @param [Exception]
    def render_sushi_exception(error)
      render json: error, status: :unprocessable_entity
    end
    rescue_from Sushi::Error::Exception, with: :render_sushi_exception

    public

    ##
    # needs to include the following filters: begin & end date, item ID
    #
    #
    # When given an item_id parameter, filter the results to only that item_id.
    #
    # @note We should not need to find the record in ActiveFedora; hopefully we have all we need in
    #       the stats database.
    def item_report
      @report = Sushi::ItemReport.new(params, account: current_account)
      render json: @report
    end

    def platform_report
      @report = Sushi::PlatformReport.new(params, account: current_account)
      render json: @report
    end

    def platform_usage
      @report = Sushi::PlatformUsageReport.new(params, account: current_account)
      render json: @report
    end

    def server_status
      @status = Sushi::ServerStatus.new(account: current_account).server_status
      render json: @status
    end

    def report_list
      @report = Sushi::ReportList.new
      render json: @report
    end
  end
end
