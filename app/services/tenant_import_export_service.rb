# frozen_string_literal: true

class TenantImportExportService
  attr_reader :account

  def initialize(account:)
    @account = account
  end

  def export
    switch!(account)
    attrs = Site.instance.attributes
    attrs.to_yaml
  end

  private


end
