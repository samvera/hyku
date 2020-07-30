# frozen_string_literal: true

module ActiveJobTenant
  extend ActiveSupport::Concern

  included do
    attr_accessor :tenant

    attr_writer :current_account
  end

  module ClassMethods
    def deserialize(job_data)
      Honeybadger.context(job_data: job_data)
      super.tap do |job|
        job.tenant = job_data['tenant']
        job.current_account = nil
      end
    end

    def non_tenant_job?
      @non_tenant_job
    end

    def non_tenant_job
      @non_tenant_job = true
    end
  end

  def serialize
    super.merge('tenant' => Apartment::Tenant.current)
  end

  def perform_now
    if non_tenant_job?
      super
    else
      switch do
        super
      end
    end
  end

  private

    delegate :non_tenant_job?, to: :class

    def current_account
      @current_account ||= Account.find_by(tenant: current_tenant)
    end

    def current_tenant
      tenant || Apartment::Tenant.current
    end

    def switch
      Apartment::Tenant.switch(current_tenant) do
        yield
      end
    end
end
