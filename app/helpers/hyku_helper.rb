# frozen_string_literal: true

module HykuHelper
  def multitenant?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MULTITENANT', false))
  end

  def current_account
    @current_account ||= Account.from_request(request)
    @current_account ||= Account.single_tenant_default
  end

  def admin_host?
    return false unless multitenant?

    Account.canonical_cname(request.host) == Account.admin_host
  end

  def admin_only_tenant_creation?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_ADMIN_ONLY_TENANT_CREATION', false))
  end

  def parent_path(parent_doc)
    model = parent_doc['has_model_ssim'].first
    path = "hyrax_#{model.underscore}_path"
    main_app.send(path, parent_doc.id)
  end
end
