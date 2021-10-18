# frozen_string_literal: true

module SharedSearchHelper
  # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
  def generate_work_url(model, request)
    model = model.with_indifferent_access
    request_protocol = request.protocol || 'http://'
    request_port = request.port
    request_host = request.host

    cname = model["account_cname_tesim"]
    account_cname = cname.class == Array ? cname.try(:first) : cname

    has_model = model["has_model_ssim"].first.underscore.pluralize
    # returns a symbol not a string
    id = model[:id]

    if Rails.env.development? || Rails.env.test?
      "#{request_protocol}#{account_cname || request_host}:#{request_port}/concern/#{has_model}/#{id}"
    else
      "#{request_protocol}#{account_cname || request_host}/concern/#{has_model}/#{id}"
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
end
