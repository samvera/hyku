# frozen_string_literal: true

module SharedSearchHelper
  def generate_work_url(model, request)
    # needed because some attributes eg id is a symbol 7 others are string
    if model.class == Hyrax::IiifAv::IiifFileSetPresenter
      has_model = model.model_name.plural
      id = model.id
      account_cname = request.server_name
    else
      model = model.to_h.with_indifferent_access

      cname = model["account_cname_tesim"]
      account_cname = Array.wrap(cname).first

      has_model = model["has_model_ssim"].first.underscore.pluralize
      id = model["id"]
    end
    request_params = %i[protocol host port].map { |method| ["request_#{method}".to_sym, request.send(method)] }.to_h
    get_url(id: id, request: request_params, account_cname: account_cname, has_model: has_model)
  end

  private

    def get_url(id:, request:, account_cname:, has_model:)
      new_url = "#{request[:request_protocol]}#{account_cname || request[:request_host]}"
      new_url += ":#{request[:request_port]}" if Rails.env.development? || Rails.env.test?
      new_url += case has_model
                 when "collections"
                   "/#{has_model}/#{id}"
                 else
                   "/concern/#{has_model}/#{id}"
                 end
      new_url
    end
end
