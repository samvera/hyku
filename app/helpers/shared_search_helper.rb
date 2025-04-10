# frozen_string_literal: true

# A helper module that generates work URLs based on models and request parameters.
module SharedSearchHelper
  # Generates a URL for the given model with optional query parameters.
  #
  # @param model [Object] the model object, typically a work or collection
  # @param request [ActionDispatch::Request] the current HTTP request object
  # @param params [Hash] additional query parameters (e.g., search queries)
  # @return [String] the generated URL with or without query parameters
  def generate_work_url(model, request, params = {})
    id, base_route_name, account_cname = extract_model_info(model, request)
    request_params = extract_request_params(request)
    url = build_url(id, request_params, account_cname, base_route_name)

    append_query_params(url, model, params)
  end

  private

  # Extracts the model ID, route name, and account cname from the model and request.
  #
  # @param model [Object] the model object (e.g., Hyrax::IiifAv::IiifFileSetPresenter or others)
  # @param request [ActionDispatch::Request] the current HTTP request object
  # @return [Array<String>] a tuple containing the model's ID, route name, and account cname
  def extract_model_info(model, request)
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
    [id, base_route_name, account_cname]
  end

  # Extracts protocol, host, and port information from the request.
  #
  # @param request [ActionDispatch::Request] the current HTTP request object
  # @return [Hash] a hash containing the protocol, host, and port extracted from the request
  def extract_request_params(request)
    %i[protocol host port].map { |method| ["request_#{method}".to_sym, request.send(method)] }.to_h
  end

  # Builds the base URL for the given model and request information.
  #
  # @param id [String] the model's ID
  # @param request_params [Hash] the extracted request parameters (protocol, host, port)
  # @param account_cname [String, nil] the account cname, if applicable
  # @param base_route_name [String] the base route name (e.g., 'works', 'collections')
  # @return [String] the constructed base URL
  def build_url(id, request_params, account_cname, base_route_name)
    get_url(id: id, request: request_params, account_cname: account_cname, base_route_name: base_route_name)
  end

  # Appends the appropriate query parameters to the base URL based on the model and params.
  #
  # @param url [String] the base URL
  # @param model [Object] the model object (e.g., work or collection)
  # @param params [Hash] the query parameters, which may include search queries
  # @return [String] the URL with appended query parameters, if applicable
  def append_query_params(url, model, params)
    if params[:q].present? && model.any_highlighting_in_all_text_fields?
      "#{url}?parent_query=#{params[:q]}&highlight=true"
    else
      url
    end
  end

  # Constructs a URL with the given parameters.
  #
  # @param id [String] the model's ID
  # @param request [Hash] the request parameters (protocol, host, port)
  # @param account_cname [String, nil] the account cname, if applicable
  # @param base_route_name [String] the base route name (e.g., 'works', 'collections')
  # @return [String] the constructed URL
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
