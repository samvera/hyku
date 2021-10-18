# frozen_string_literal: true

module SharedSearchHelper
  def generate_work_url(model, request)
    # needed because some attributes eg id is a symbol 7 others are string
    model = model.with_indifferent_access
    request_protocol = request.protocol || 'http://'
    request_port = request.port
    request_host = request.host

    cname = model["account_cname_tesim"]
    account_cname = cname.class == Array ? cname.try(:first) : cname

    has_model = model["has_model_ssim"].first.underscore.pluralize
    id = model["id"]

    request_params = { request_protocol: request_protocol, request_host: request_host, request_port: request_port }
    get_url(id: id, request: request_params, account_cname: account_cname, has_model: has_model)
  end

  private

    def get_url(id:, request:, account_cname:, has_model:)
      if Rails.env.development? || Rails.env.test?
        "#{request[:request_protocol]}#{account_cname || request[:request_host]}:#{request[:request_port]}/concern/#{has_model}/#{id}"
      else
        "#{request[:request_protocol]}#{account_cname || request[:request_host]}/concern/#{has_model}/#{id}"
      end
    end
end
