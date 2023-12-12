# frozen_string_literal: true

class CreateDefaultAdminSetJob < ApplicationJob
  def perform(_account)
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
  end
end
