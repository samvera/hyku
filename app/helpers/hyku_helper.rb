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

  # We don't want to use Turbolinks because it blocks the
  # redirects from AF works to Valkyrie works in the edit and show
  # TODO: When there are no more AF works, we can remove this and remove the ENV variable
  def block_valkyrie_redirect?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_BLOCK_VALKYRIE_REDIRECT', true))
  end

  def parent_path(parent_doc)
    model = case parent_doc
            when Hyrax::Resource, ActiveFedora::Base
              parent_doc
            when SolrDocument
              parent_doc['has_model_ssim'].first.constantize
            else
              raise "Unknown parent_doc type: #{parent_doc.class}"
            end

    path = "#{model.model_name.singular_route_key}_path"
    main_app.send(path, parent_doc.id)
  end
end
