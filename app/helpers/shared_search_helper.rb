# frozen_string_literal: true

module SharedSearchHelper
  def generate_work_url(model, request)
    # handle the various types of info we receive:
    if model.class == Hyrax::IiifAv::IiifFileSetPresenter
      base_route_name = model.model_name.plural
      id = model.id
      account_cname = request.server_name
    else
      model_hash = model.to_h.with_indifferent_access
   
      base_route_name = model_hash["has_model_ssim"].first.constantize.model_name.plural
      id = model_hash["id"]
      account_cname = Array.wrap(model_hash["account_cname_tesim"]).first
    end

    request_params = %i[protocol host port].map { |method| ["request_#{method}".to_sym, request.send(method)] }.to_h
    url = get_url(id:, request: request_params, account_cname:, base_route_name:)

    # pass search query params to work show page
    params[:q].present? ? "#{url}?q=#{params[:q]}" : url
  end

  private

  def get_url(id:, request:, account_cname:, base_route_name:)
    new_url = "#{request[:request_protocol]}#{account_cname || request[:request_host]}"
    new_url += ":#{request[:request_port]}" if Rails.env.development? || Rails.env.test?
    new_url += case base_route_name
               when "collections"
                 "/#{base_route_name}/#{id}"
               else
                 "/concern/#{base_route_name}/#{id}"
               end
    new_url
  end
end
